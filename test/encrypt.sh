#!/bin/bash
if [[ $# -ne 2 ]]; then
    echo "Usage: ./encrypt.sh <b64-encoded key> <plaintext string>"
    exit
fi

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

MASTER_KEY_B64=$1
echo -n $2 > "$SCRIPT_DIR/input.txt"

VERSION='01'
IV_SIZE=16
KEY_SIZE=32
# First KEY_SIZE of bytes of master key are used for encryption key
# Decode master key and print in HEX. Cut output after KEY_SIZE bytes. First line is the encryption key.
ENCRYPTION_KEY_HEX=$(echo $MASTER_KEY_B64 | base64 -d |  xxd -p -c $KEY_SIZE | head -n 1)
# Second line is the message authentication key
MAC_KEY_HEX=$(echo $MASTER_KEY_B64 | base64 -d |  xxd -p -c $KEY_SIZE | tail +2 | head -n 1)

# Generate a random initial vector
IV=$(openssl rand $IV_SIZE | xxd -p -c $IV_SIZE)

# Decrypt the message using AES-256-CBC with the encryption key and initial vector. Save binary results in input.txt.enc
openssl enc -aes-256-cbc -nosalt -e \
        -in "$SCRIPT_DIR/input.txt" -out "$SCRIPT_DIR/input.txt.enc" \
        -K $ENCRYPTION_KEY_HEX -iv $IV

# Concat the pieces using HEX strings: VERSION - IV - ENCRYPTED_MESSAGE
echo -n $VERSION$IV$(xxd -p -c 256 "$SCRIPT_DIR/input.txt.enc") | xxd -r -p > "$SCRIPT_DIR/input-hmac.bin"
# Calculate tag/HMAC with HMAC-SHA256. Save binary result in input-hmac.bin
openssl dgst -sha256 -mac hmac -macopt hexkey:$MAC_KEY_HEX -binary -out "$SCRIPT_DIR/hmac.bin" "$SCRIPT_DIR/input-hmac.bin"

# Add tag to data by concatenating HEX strings: VERSION - IV - ENCRYPTED_MESSAGE - TAG
# Base64URL decode binary format
echo -n $(xxd -p -c 256 "$SCRIPT_DIR/input-hmac.bin")$(xxd -p -c 32 "$SCRIPT_DIR/hmac.bin") | xxd -r -p | base64 | tr '+/' '-_' | tr -d '='

# Clean up
rm "$SCRIPT_DIR/input.txt" "$SCRIPT_DIR/input.txt.enc" "$SCRIPT_DIR/input-hmac.bin" "$SCRIPT_DIR/hmac.bin"