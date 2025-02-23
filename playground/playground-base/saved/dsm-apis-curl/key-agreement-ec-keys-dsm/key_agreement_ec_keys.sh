#!/bin/bash

set -xeo pipefail

## For an example, we will create 2 different groups in DSM, one for Alice and one for Bob to showcase 2 different parties.
## Also, we will create an App for Alice and a different App for Bob to ensure they have a different access.
##
## For this example, we will make Alice's and Bob's public key accessible publically (so that Alice can access Bob's public key and vice versa).

## Following env needs to be set:

# FORTANIX_API_ENDPOINT=""
# FORTANIX_ACCOUNT_ID=""

# # Alice
# FORTANIX_ALICE_API_KEY=""
# FORTANIX_ALICE_GROUP_ID=""
# ALICE_EC_KEY_NAME="AliceKey"
# AGREED_KEY_NAME_IN_ALICE_GROUP="AgreedKey_inAliceGroup"
# ALICE_DERIVED_KEY_NAME="AliceDerivedKey"

# # Bob
# FORTANIX_BOB_API_KEY=""
# FORTANIX_BOB_GROUP_ID=""
# BOB_EC_KEY_NAME="BobKey"
# AGREED_KEY_NAME_IN_BOB_GROUP="AgreedKey_inBobGroup"
# BOB_DERIVED_KEY_NAME="BobDerivedKey16"

delete_key_id() {
    local key_id=$1; shift
    local api_key=$1; shift

    if [ -n "$key_id" ]
    then
        echo "Deleting key $key_id"
        curl -X DELETE "$FORTANIX_API_ENDPOINT/crypto/v1/keys/$key_id" -H "Authorization: Basic $api_key"
    fi
}

# Delete created keys if an error occurs
handle_exit() {
    while true
    do
        read -p "Delete all extra files, keys, etc created by this script? (y/n)?" choice
        case "$choice" in 
            y|Y ) break ;;
            n|N ) return ;;
            * ) >&2 echo "invalid response "; continue ;;
        esac
    done

    delete_key_id "$ALICE_EC_KEY_ID" "$FORTANIX_ALICE_API_KEY"
    delete_key_id "$BOB_EC_KEY_ID" "$FORTANIX_BOB_API_KEY"
    delete_key_id "$ALICE_PUBLIC_KEY_IN_BOB_GROUP_KID" "$FORTANIX_BOB_API_KEY"
    delete_key_id "$BOB_PUBLIC_KEY_IN_ALICE_GROUP_KID" "$FORTANIX_ALICE_API_KEY"
    delete_key_id "$ALICE_AGREED_KEY_ID" "$FORTANIX_ALICE_API_KEY"
    delete_key_id "$BOB_AGREED_KEY_ID" "$FORTANIX_BOB_API_KEY"
    delete_key_id "$ALICE_DERIVED_KEY_ID" "$FORTANIX_ALICE_API_KEY"
    delete_key_id "$BOB_DERIVED_KEY_ID" "$FORTANIX_BOB_API_KEY"

    rm \
        fortanix_create_alice_ec_key_req.json \
        fortanix_create_bob_ec_key_req.json \
        fortanix_import_bob_public_key_for_alice.json \
        fortanix_import_alice_public_key_for_bob.json \
        fortanix_alice_agree_key_req.json \
        fortanix_bob_agree_key_req.json \
        fortanix_plain_export_alice_agreed_key.json \
        fortanix_plain_export_bob_agreed_key.json \
        fortanix_derive_alice_key_req.json \
        fortanix_derive_bob_key_req.json \
        fortanix_plain_export_alice_derived_key.json \
        fortanix_plain_export_bob_derived_key.json
}

trap 'handle_exit' EXIT

##
## Create Alice's EC key
##

# Request for creating Alice's EC key in DSM
# `publish_public_key` in the request makes the key's public part publically available without any auth.
cat << EOF > fortanix_create_alice_ec_key_req.json
{
  "enabled": true,
  "key_ops": [
    "AGREEKEY",
    "APPMANAGEABLE"
  ],
  "publish_public_key": {
    "state": "enabled",
    "list_previous_version": false
  },
  "name": "${ALICE_EC_KEY_NAME}",
  "obj_type": "EC",
  "elliptic_curve": "NistP256",
  "group_id": "${FORTANIX_ALICE_GROUP_ID}"
}
EOF

# Create Alice's EC key in DSM
ALICE_CREATE_EC_KEY_OUTPUT="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys" -H "Authorization: Basic $FORTANIX_ALICE_API_KEY" -d @./fortanix_create_alice_ec_key_req.json )"
ALICE_EC_KEY_ID="$( echo "$ALICE_CREATE_EC_KEY_OUTPUT" | jq -r '.kid' )"

##
## Create Bob's EC key
##

# Request for creating Bob's EC key in DSM
# `publish_public_key` in the request makes the key's public part publically available without any auth.
cat << EOF > fortanix_create_bob_ec_key_req.json
{
  "enabled": true,
  "key_ops": [
    "AGREEKEY",
    "APPMANAGEABLE"
  ],
  "publish_public_key": {
    "state": "enabled",
    "list_previous_version": false
  },
  "name": "${BOB_EC_KEY_NAME}",
  "obj_type": "EC",
  "elliptic_curve": "NistP256",
  "group_id": "${FORTANIX_BOB_GROUP_ID}"
}
EOF

# Create Bob's EC key in DSM
BOB_CREATE_EC_KEY_OUTPUT="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys" -H "Authorization: Basic $FORTANIX_BOB_API_KEY" -d @./fortanix_create_bob_ec_key_req.json )"
BOB_EC_KEY_ID="$( echo "$BOB_CREATE_EC_KEY_OUTPUT" | jq -r '.kid' )"

##
## Now, Alice will call `POST crypto/v1/agree` with her private key and Bob's public key and Bob will call
## `POST crypto/v1/agree` will Alice' public key and his private key. Both of them will get the same secret.
##
## For that, Alice would need to know Bob's public key and vice versa. 

# Getting Bob's public key (no auth required as Bob set "publish_public_key" to enabled) and importing it to Alice's group.
# Basically creating a new Sobject in Alice's group which contains Bob's public key.

BOB_PUBLIC_KEY="$( curl -X GET "$FORTANIX_API_ENDPOINT/crypto/v1/pubkey/$FORTANIX_ACCOUNT_ID/$BOB_EC_KEY_NAME" | jq -r .\"$BOB_EC_KEY_ID\" )"
BOB_PUBLIC_KEY_IN_ALICE_GROUP_NAME="${BOB_EC_KEY_NAME}_inAliceGroup"
cat << EOF > fortanix_import_bob_public_key_for_alice.json
{
  "enabled": true,
  "key_ops": [
    "AGREEKEY",
    "APPMANAGEABLE"
  ],
  "publish_public_key": {
    "state": "enabled",
    "list_previous_version": false
  },
  "name": "${BOB_PUBLIC_KEY_IN_ALICE_GROUP_NAME}",
  "obj_type": "EC",
  "value": "${BOB_PUBLIC_KEY}",
  "elliptic_curve": "NistP256",
  "group_id": "${FORTANIX_ALICE_GROUP_ID}"
}
EOF
BOB_PUBLIC_KEY_IMPORT_OUTPUT="$( curl -X PUT "$FORTANIX_API_ENDPOINT/crypto/v1/keys" -H "Authorization: Basic $FORTANIX_ALICE_API_KEY" -d @./fortanix_import_bob_public_key_for_alice.json )"
BOB_PUBLIC_KEY_IN_ALICE_GROUP_KID="$( echo "$BOB_PUBLIC_KEY_IMPORT_OUTPUT" | jq -r '.kid' )"

# Getting Alice's public key (no auth required as Alice set "publish_public_key" to enabled) and importing it to Bob's group.
# Basically creating a new Sobject in Bob's group which contains Alice's public key.

ALICE_PUBLIC_KEY="$( curl -X GET "$FORTANIX_API_ENDPOINT/crypto/v1/pubkey/$FORTANIX_ACCOUNT_ID/$ALICE_EC_KEY_NAME" | jq -r .\"$ALICE_EC_KEY_ID\" )"
ALICE_PUBLIC_KEY_IN_BOB_GROUP_NAME="${ALICE_EC_KEY_NAME}_inBobGroup"
cat << EOF > fortanix_import_alice_public_key_for_bob.json
{
  "enabled": true,
  "key_ops": [
    "AGREEKEY",
    "APPMANAGEABLE"
  ],
  "publish_public_key": {
    "state": "enabled",
    "list_previous_version": false
  },
  "name": "${ALICE_PUBLIC_KEY_IN_BOB_GROUP_NAME}",
  "obj_type": "EC",
  "value": "${ALICE_PUBLIC_KEY}",
  "elliptic_curve": "NistP256",
  "group_id": "${FORTANIX_BOB_GROUP_ID}"
}
EOF
ALICE_PUBLIC_KEY_IMPORT_OUTPUT="$( curl -X PUT "$FORTANIX_API_ENDPOINT/crypto/v1/keys" -H "Authorization: Basic $FORTANIX_BOB_API_KEY" -d @./fortanix_import_alice_public_key_for_bob.json )"
ALICE_PUBLIC_KEY_IN_BOB_GROUP_KID="$( echo "$ALICE_PUBLIC_KEY_IMPORT_OUTPUT" | jq -r '.kid' )"

##
## Agree key from Alice
##

# Request for agree key from Alice
# WARNING: Added EXPORT only for verifying key value later. Not having EXPORT is recommended.
cat << EOF > fortanix_alice_agree_key_req.json
{
  "private_key": {
    "name": "${ALICE_EC_KEY_NAME}"
  },
  "public_key": {
    "name": "${BOB_PUBLIC_KEY_IN_ALICE_GROUP_NAME}"
  },
  "mechanism": "diffie_hellman",
  "obj_type": "EC",
  "name": "${AGREED_KEY_NAME_IN_ALICE_GROUP}",
  "group_id": "${FORTANIX_ALICE_GROUP_ID}",
  "key_type": "SECRET",
  "key_size": 256,
  "enabled": true,
  "key_ops": [
    "DERIVEKEY",
    "APPMANAGEABLE",
    "EXPORT"
  ]
}
EOF
ALICE_AGREE_KEY_OUTPUT="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/agree" -H "Authorization: Basic $FORTANIX_ALICE_API_KEY" -d @./fortanix_alice_agree_key_req.json )"
ALICE_AGREED_KEY_ID="$( echo "$ALICE_AGREE_KEY_OUTPUT" | jq -r '.kid' )"

##
## Agree key from Bob
##

# Request for agree key from Bob
# WARNING: Added EXPORT only for verifying key value later. Not having EXPORT is recommended.
cat << EOF > fortanix_bob_agree_key_req.json
{
  "private_key": {
    "name": "${BOB_EC_KEY_NAME}"
  },
  "public_key": {
    "name": "${ALICE_PUBLIC_KEY_IN_BOB_GROUP_NAME}"
  },
  "mechanism": "diffie_hellman",
  "obj_type": "EC",
  "name": "${AGREED_KEY_NAME_IN_BOB_GROUP}",
  "group_id": "${FORTANIX_BOB_GROUP_ID}",
  "key_type": "SECRET",
  "key_size": 256,
  "enabled": true,
  "key_ops": [
    "DERIVEKEY",
    "APPMANAGEABLE",
    "EXPORT"
  ]
}
EOF
BOB_AGREE_KEY_OUTPUT="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/agree" -H "Authorization: Basic $FORTANIX_BOB_API_KEY" -d @./fortanix_bob_agree_key_req.json )"
BOB_AGREED_KEY_ID="$( echo "$BOB_AGREE_KEY_OUTPUT" | jq -r '.kid' )"

##
## Keys generated in Alice's and Bob's group upon `POST /crypto/v1/agree` should have the same key value.
##

# Request for plain export of Alice's agreed key
cat << EOF > fortanix_plain_export_alice_agreed_key.json
{
  "kid": "${ALICE_AGREED_KEY_ID}"
}
EOF
DSM_PLAIN_EXPORT_ALICE_AGREED_KEY_VALUE="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys/export" \
    -H "Authorization: Basic $FORTANIX_ALICE_API_KEY" -d @./fortanix_plain_export_alice_agreed_key.json | jq -r '.value' )"

# Request for plain export of Bob's agreed key
cat << EOF > fortanix_plain_export_bob_agreed_key.json
{
  "kid": "${BOB_AGREED_KEY_ID}"
}
EOF
DSM_PLAIN_EXPORT_BOB_AGREED_KEY_VALUE="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys/export" \
    -H "Authorization: Basic $FORTANIX_BOB_API_KEY" -d @./fortanix_plain_export_bob_agreed_key.json | jq -r '.value' )"

if [ "$DSM_PLAIN_EXPORT_ALICE_AGREED_KEY_VALUE" == "$DSM_PLAIN_EXPORT_BOB_AGREED_KEY_VALUE" ]
then
    echo "SUCCESS - Agreed key generated by Alice is same as Bob's"
else
    echo "FAILURE - Agreed key generated by Alice is not same as Bob's"
fi

##
## It is not recommended to use the shared secret directly. Further, `POST /crypto/v1/derive` can be used to derive new key.
##

# Derive a key from Alice's agreed key using HKDF
cat << EOF > fortanix_derive_alice_key_req.json
{
  "key": {
    "kid": "${ALICE_AGREED_KEY_ID}"
  },
  "name": "${ALICE_DERIVED_KEY_NAME}",
  "key_size": 256,
  "key_type": "AES",
  "mechanism": {
    "hkdf": {
      "hash_alg": "Sha256",
      "info": "$(echo -n 'my hkdf info' | base64)",
      "salt": "$(echo -n 'my hkdf salt' | base64)"
    }
  },
  "key_ops": [
    "ENCRYPT",
    "DECRYPT",
    "WRAPKEY",
    "UNWRAPKEY",
    "APPMANAGEABLE",
    "EXPORT"
  ],
  "enabled": true
}
EOF

ALICE_DERIVED_KEY_OUTPUT="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/derive" -H "Authorization: Basic $FORTANIX_ALICE_API_KEY" -d @./fortanix_derive_alice_key_req.json )"
ALICE_DERIVED_KEY_ID="$( echo "$ALICE_DERIVED_KEY_OUTPUT" | jq -r '.kid' )"

# Derive a key from Bob's agreed key using HKDF
cat << EOF > fortanix_derive_bob_key_req.json
{
  "key": {
    "kid": "${BOB_AGREED_KEY_ID}"
  },
  "name": "${BOB_DERIVED_KEY_NAME}",
  "key_size": 256,
  "key_type": "AES",
  "mechanism": {
    "hkdf": {
      "hash_alg": "Sha256",
      "info": "$(echo -n 'my hkdf info' | base64)",
      "salt": "$(echo -n 'my hkdf salt' | base64)"
    }
  },
  "key_ops": [
    "ENCRYPT",
    "DECRYPT",
    "WRAPKEY",
    "UNWRAPKEY",
    "APPMANAGEABLE",
    "EXPORT"
  ],
  "enabled": true
}
EOF

BOB_DERIVED_KEY_OUTPUT="$(curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/derive" -H "Authorization: Basic $FORTANIX_BOB_API_KEY" -d @./fortanix_derive_bob_key_req.json)"
BOB_DERIVED_KEY_ID="$(echo "$BOB_DERIVED_KEY_OUTPUT" | jq -r '.kid')"

##
## Keys derived from Alice's and Bob's agreed key should have the same key value.
##

# Request for plain export of Alice's derived key
cat << EOF > fortanix_plain_export_alice_derived_key.json
{
  "kid": "${ALICE_DERIVED_KEY_ID}"
}
EOF
DSM_PLAIN_EXPORT_ALICE_DERIVED_KEY_VALUE="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys/export" \
    -H "Authorization: Basic $FORTANIX_ALICE_API_KEY" -d @./fortanix_plain_export_alice_derived_key.json | jq -r '.value' )"

# Request for plain export of Bob's derived key
cat << EOF > fortanix_plain_export_bob_derived_key.json
{
  "kid": "${BOB_DERIVED_KEY_ID}"
}
EOF
DSM_PLAIN_EXPORT_BOB_DERIVED_KEY_VALUE="$( curl -X POST "$FORTANIX_API_ENDPOINT/crypto/v1/keys/export" \
    -H "Authorization: Basic $FORTANIX_BOB_API_KEY" -d @./fortanix_plain_export_bob_derived_key.json | jq -r '.value' )"

if [ "$DSM_PLAIN_EXPORT_ALICE_DERIVED_KEY_VALUE" == "$DSM_PLAIN_EXPORT_BOB_DERIVED_KEY_VALUE" ]
then
    echo "SUCCESS - Key derived by Alice is same as Bob's"
else
    echo "FAILURE - Key derived by Alice is not same as Bob's"
fi

##
## Now Alice can wrap/encrypt with this derived key and Bob can unwrap/decrypt since they both have the same symmetric key.
## This can be done in a similar way that we did in wrap/unwrap using RSA. Instead, we would need to use AES with any of its supported modes.
## Also, unlike RSA, parameters like iv would need to be same for both the parties.
##
## Following are the supported algos: https://support.fortanix.com/hc/en-us/articles/360016160411-Algorithm-Support


