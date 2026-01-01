#!/bin/bash

set -e

# Check if .env.example exists but .env doesn't, then copy it
if [ -f '.env.example' ] && [ ! -f '.env' ]; then
    echo ">> .env not found, generating from .env.example"
    cp .env.example .env
fi

touch public.env
touch .env

publicEnvironmentSetupFile=$(mktemp)
if [ -f 'public.env' ]; then
    cat 'public.env' | while read line; do
      if [ "${#line}" -gt 0 ] && [[ ! $line =~ ^# ]]; then
        echo "export $line";
      fi
    done > "${publicEnvironmentSetupFile}"
    source "${publicEnvironmentSetupFile}"
else
    echo '>> public.env not found'
    exit 1
fi

environmentSetupFile=$(mktemp)
if [ -f '.env' ]; then
    cat '.env' | while read line; do
        if [ "${#line}" -gt 0 ] && [[ ! $line =~ ^# ]]; then
          echo "export $line";
        fi
    done > "${environmentSetupFile}"
    source "${environmentSetupFile}"
    rm -f "${environmentSetupFile}"
fi

if [ -f 'Dockerfile' ]; then
    docker image rm -f "${IMAGE_NAME}" || true
    docker build -t "${IMAGE_NAME}" .
fi

# Check if the network exists, if not, create it
if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo ">> Creating network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME"
else
    echo ">> Network $NETWORK_NAME already exists"
fi



