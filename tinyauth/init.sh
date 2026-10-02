#!/bin/bash
# Initialize Tinyauth data directory and create the first user

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"
DATA_DIR="./local/data"

mkdir -p "${DATA_DIR}"

read -p "This will create a new Tinyauth user with the provided username and password. Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting user creation."
    exit 0
fi

read -p "Enter the new Tinyauth username: " TINYAUTH_USERNAME
read -s -p "Enter the new Tinyauth password: " TINYAUTH_PASSWORD
echo

# Use htpasswd instead of tinyauth's own CLI: its TUI output wraps long
# hashes across lines when not attached to a TTY, which breaks parsing.
NEW_USER=$(docker run -i --rm httpd:2.4-alpine htpasswd -nbB "${TINYAUTH_USERNAME}" "${TINYAUTH_PASSWORD}")

if [ -z "${NEW_USER}" ]; then
    echo ">> Failed to generate user hash. Aborting."
    exit 1
fi

if [ -n "${TINYAUTH_AUTH_USERS}" ]; then
    NEW_USER="${TINYAUTH_AUTH_USERS},${NEW_USER}"
fi

touch .env
if grep -q '^TINYAUTH_AUTH_USERS=' .env; then
    sed -i.bak "s|^TINYAUTH_AUTH_USERS=.*|TINYAUTH_AUTH_USERS=${NEW_USER}|" .env && rm -f .env.bak
else
    echo "TINYAUTH_AUTH_USERS=${NEW_USER}" >> .env
fi

echo ">> User '${TINYAUTH_USERNAME}' added. TINYAUTH_AUTH_USERS updated in .env"

mkdir -p ./local
touch "${INIT_FLAG}"
