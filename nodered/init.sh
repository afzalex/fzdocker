#!/bin/bash
# Initialize Node-RED data directory and credential secret

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

mkdir -p "${DATA_DIR}"

mark_initialized() {
    mkdir -p ./local
    touch "${INIT_FLAG}"
}

if grep -q '^NODE_RED_CREDENTIAL_SECRET=' .env 2>/dev/null; then
    echo "NODE_RED_CREDENTIAL_SECRET already set in .env"
    mark_initialized
    exit 0
fi

read -p "Generate a credential encryption secret for Node-RED flows? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping credential secret generation."
    mark_initialized
    exit 0
fi

secret=$(openssl rand -hex 32)
echo "NODE_RED_CREDENTIAL_SECRET=${secret}" >> .env
echo "Credential secret written to .env"
mark_initialized
