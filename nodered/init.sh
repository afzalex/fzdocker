#!/bin/bash
# Initialize Node-RED data directory and credential secret

source ../run-preprocess.tpl.sh

mkdir -p "${DATA_DIR}"

if grep -q '^NODE_RED_CREDENTIAL_SECRET=' .env 2>/dev/null; then
    echo "NODE_RED_CREDENTIAL_SECRET already set in .env"
    exit 0
fi

read -p "Generate a credential encryption secret for Node-RED flows? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping credential secret generation."
    exit 0
fi

secret=$(openssl rand -hex 32)
echo "NODE_RED_CREDENTIAL_SECRET=${secret}" >> .env
echo "Credential secret written to .env"
