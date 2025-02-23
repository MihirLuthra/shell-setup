package main

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
)

type KeyPair struct {
	Private []byte `json:"private"`
	Public  []byte `json:"public"`
}

type TUFKey struct {
  id    string
	Type  string  `json:"keytype"`
	Value KeyPair `json:"keyval"`
}

// MarshalCanonical ensures JSON is marshaled in a canonical way.
func MarshalCanonical(v interface{}) ([]byte, error) {
	return json.Marshal(v) // Replace with custom canonical JSON if necessary
}

func main() {
	// Replace this with your actual Base64-encoded public key.
	base64PublicKey := "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEVyWQ7SCrNJeUiH8w02HzcokB35hifMuR1CACLvd+cncbWtmUsmQBOgnfkUHkdEWyUrxAhZK7i/p4AhqV073pzg=="

	// Decode the Base64 public key to bytes.
	decodedPublicKey, err := base64.StdEncoding.DecodeString(base64PublicKey)
	if err != nil {
		log.Fatalf("Error decoding Base64 public key: %v", err)
	}

	// Create the TUFKey structure.
	pubK := TUFKey{
		Type: "ecdsa", // Replace with the appropriate key type (e.g., "rsa", "ecdsa").
		Value: KeyPair{
			Private: nil, // Omitted due to `omitempty`.
			Public:  decodedPublicKey,
		},
	}

	// Marshal the TUFKey structure into canonical JSON.
	data, err := MarshalCanonical(&pubK)
	if err != nil {
		log.Fatalf("Error generating JSON: %v", err)
	}

  fmt.Println(string(data))

	// Calculate the SHA-256 digest of the JSON data.
	digest := sha256.Sum256(data)
	keyID := hex.EncodeToString(digest[:])

	// Print the resulting key ID.
	fmt.Printf("Key ID: %s\n", keyID)
}

