#!/bin/bash

set -exo pipefail

# Set env vars to be used below
#FORTANIX_API_ENDPOINT=<your_api_endpoint>
#FORTANIX_API_KEY=<you_app_api_key>
#FORTANIX_GROUP_ID=<your_group_id>
#FORTANIX_WRAPPED_KEY_NAME=<AES key name to generate in DSM>
#FORTANIX_WRAPPING_KEY_NAME=<RSA key name to import in DSM>

##
## Create AES key in DSM
##

# Request for creating an AES key in DSM
cat << EOF > fortanix_create_aes_key_req.json
{
  "enabled": true,
  "key_ops": [
    "ENCRYPT",
    "DECRYPT",
    "WRAPKEY",
    "UNWRAPKEY",
    "DERIVEKEY",
    "MACGENERATE",
    "MACVERIFY",
    "APPMANAGEABLE",
    "EXPORT"
  ],
  "key_size": 256,
  "name": "${FORTANIX_WRAPPED_KEY_NAME}",
  "obj_type": "AES",
  "group_id": "${FORTANIX_GROUP_ID}"
}
EOF

# Create AES key in DSM
curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys" -H "Authorization: Basic $FORTANIX_API_KEY" -d @./fortanix_create_aes_key_req.json 

##
## Generate RSA key locally and import to DSM
##

# Create a RSA key with OpenSSL
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096
openssl rsa -pubout -in private_key.pem -out public_key.pem

# For public_key.pem, just removing PEM headers and adding "\n" in place of actual new lines.
RSA_PUBLIC_KEY_VALUE="$(cat public_key.pem | \
  sed '/-----BEGIN PUBLIC KEY-----/d' | \
  sed '/-----END PUBLIC KEY-----/d' | \
  tr -d '\n' | \
  fold -w64 | \
  awk '{print $0 "\\n"}' | \
  tr -d '\n' | \
  sed 's/\\n$//')"

# Request for importing the above RSA public key in DSM
cat << EOF > fortanix_import_rsa_public_key_req.json
{
  "enabled": true,
  "key_ops": [
    "APPMANAGEABLE",
    "EXPORT",
    "WRAPKEY",
    "ENCRYPT"
  ],
  "name": "${FORTANIX_WRAPPING_KEY_NAME}",
  "obj_type": "RSA",
  "rsa": {
    "encryption_policy": [
      {
        "padding": {
          "OAEP": {
            "mgf": {
              "mgf1": {}
            }
          }
        }
      }
    ]
  },
  "value": "${RSA_PUBLIC_KEY_VALUE}",
  "group_id": "${FORTANIX_GROUP_ID}"
}
EOF

# Import RSA public key
curl -X PUT "$FORTANIX_API_ENDPOINT/crypto/v1/keys" -H "Authorization: Basic $FORTANIX_API_KEY" -d @./fortanix_import_rsa_public_key_req.json

##
## Do a wrapped export of the key
##

# Request for wrapped export
cat << EOF > fortanix_wrapped_export_req.json
{
  "key": {
    "name": "${FORTANIX_WRAPPING_KEY_NAME}"
  },
  "subject": {
    "name": "${FORTANIX_WRAPPED_KEY_NAME}"
  },
  "alg": "RSA",
  "mode": {
    "OAEP": {
      "mgf": {
        "mgf1": {
          "hash": "SHA256" 
        }
      }
    }
  }
}
EOF

# wrap and export
WRAPPED_KEY="$( curl "$FORTANIX_API_ENDPOINT/crypto/v1/wrapkey" -H "Authorization: Basic $FORTANIX_API_KEY" -d @./fortanix_wrapped_export_req.json | jq -r '.wrapped_key' )"

# base64 decode and store wrapped key
echo -n "$WRAPPED_KEY" | base64 --decode > wrapped_key.bin

##
## Unwrap the key using OpenSSL
##
openssl pkeyutl -in wrapped_key.bin -out unwrapped_aes_key.bin -inkey private_key.pem -decrypt -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256
OPENSSL_UNWRAPPED_KEY_BASE64="$( cat unwrapped_aes_key.bin | base64 )"

##
## Verify the value unwrapped by OpenSSL
##

# To achieve this, we also export the key in plain from DSM and compare it to the key unwrapped above

# Request for plain export (no wrapping before exporting from DSM)
cat << EOF > fortanix_plain_export_req.json
{
  "name": "${FORTANIX_WRAPPED_KEY_NAME}"
}
EOF

DSM_PLAIN_EXPORT_KEY_VALUE="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys/export" -H "Authorization: Basic $FORTANIX_API_KEY" -d @./fortanix_plain_export_req.json | jq -r '.value' )"

echo "Key value exported directly from DSM: $DSM_PLAIN_EXPORT_KEY_VALUE"
echo "Key value unwrapped by OpenSSL that was wrapped exported from DSM: $OPENSSL_UNWRAPPED_KEY_BASE64"

if [ "$DSM_PLAIN_EXPORT_KEY_VALUE" == "$OPENSSL_UNWRAPPED_KEY_BASE64" ]
then
    echo "SUCCESS - Value exported in plain from DSM is same as the value unwrapped by OpenSSL"
else
    echo "FAILURE - Value exported in plain from DSM is not same as the value unwrapped by OpenSSL"
fi
