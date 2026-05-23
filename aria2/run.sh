#!/bin/bash
# Runner for Aria2 + AriaNg

source ../run-preprocess.tpl.sh

mkdir -p ./local/downloads
mkdir -p ./local/config
mkdir -p ./local/AriaNg

export UID
export GID=${GID:-$(id -g)}

if [ ! -f ./local/AriaNg/index.html ]; then
    echo "Initializing AriaNg static files..."
    ariang_container=$(docker create p3terx/ariang:latest)
    docker cp "${ariang_container}:/AriaNg/." ./local/AriaNg/
    docker rm "${ariang_container}"
fi

export RPC_SECRET_STANDARD_BASE64
RPC_SECRET_STANDARD_BASE64=$(printf '%s' "${RPC_SECRET}" | base64 | tr -d '\n')

envsubst '$RPC_SECRET_STANDARD_BASE64 $RPC_PORT' < ./config/aria2-connect.js.tpl > ./local/AriaNg/aria2-connect.js

if ! grep -q 'aria2-connect.js' ./local/AriaNg/index.html; then
    sed -i 's|<script src="js/aria-ng|<script src="aria2-connect.js"></script><script src="js/aria-ng|' ./local/AriaNg/index.html
elif grep -q '<script src="aria2-connect.js"></script></head>' ./local/AriaNg/index.html; then
    sed -i 's|<script src="aria2-connect.js"></script>||' ./local/AriaNg/index.html
    sed -i 's|<script src="js/aria-ng|<script src="aria2-connect.js"></script><script src="js/aria-ng|' ./local/AriaNg/index.html
fi

envsubst < ./docker-compose.yml.tpl > ./docker-compose.yml

# Remove existing containers if --force flag is used
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing aria2 containers..."
    docker compose down --remove-orphans
fi

# Run docker compose
if [[ " $@ " =~ " --persist " ]]; then
    docker compose up -d
else
    docker compose up
fi
