#!/bin/bash
# Runner for public

export DOCKER_IMAGE=caddy:latest

source ../run-preprocess.tpl.sh

FZLAUNCHPAD_URL="https://github.com/afzalex/fzlaunchpad/releases/download/latest/fzlaunchpad.tar.gz"
MAIN_DIR=./local/sites/main

# Create local directory if it doesn't exist
mkdir -p ./local/sites

if [ ! -d "${MAIN_DIR}" ]; then
    read -p "Import latest fzlaunchpad? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmpdir=$(mktemp -d)
        trap 'rm -rf "$tmpdir"' EXIT

        echo "Downloading fzlaunchpad..."
        curl -fsSL "${FZLAUNCHPAD_URL}" -o "${tmpdir}/fzlaunchpad.tar.gz"

        mkdir -p "${MAIN_DIR}"
        tar -xzf "${tmpdir}/fzlaunchpad.tar.gz" -C "${MAIN_DIR}"

        # If the archive contains a single top-level directory, use its contents
        shopt -s nullglob
        items=("${MAIN_DIR}"/*)
        if [ ${#items[@]} -eq 1 ] && [ -d "${items[0]}" ]; then
            shopt -s dotglob
            mv "${items[0]}"/* "${MAIN_DIR}/"
            rmdir "${items[0]}"
            shopt -u dotglob
        fi
        shopt -u nullglob

        cp ./fzlaunchpad-config.yaml "${MAIN_DIR}/config.yaml"
        echo "fzlaunchpad extracted to ${MAIN_DIR}"
    else
        mkdir -p "${MAIN_DIR}"
        cp ./main-index.html "${MAIN_DIR}/index.html"
        echo "Using default main-index.html in ${MAIN_DIR}"
    fi
fi

# Process nginx.conf.tpl to substitute environment variables
if [ ! -f ./local/nginx.conf ]; then
    # Specify only the variables that are used in the template
    envsubst '${HOST}' < ./nginx.conf.tpl > ./local/nginx.conf
fi

# Remove existing container if running
if [[ " $@ " =~ " --force " ]]; then
    echo "Removing existing ${CONTAINER_NAME} container..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

docker run --name ${CONTAINER_NAME} -it \
    --network "${NETWORK_NAME}" \
    --env-file "public.env" \
    --env-file ".env" \
    -p ${PORT_MAPPING}:80 \
    $(if [[ " $@ " =~ " --persist " ]]; then echo "--restart unless-stopped -d"; else echo "--rm"; fi) \
    -v ./local/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
    -v ./local/sites:/var/www:ro \
    nginx:stable-trixie
    



