#!/bin/bash
# Initialize Mosquitto config directory and MQTT user

source ../run-preprocess.tpl.sh

INIT_FLAG="./local/.initialized"

# Create local/config directory if it doesn't exist
mkdir -p "${CONFIG_DIR}"

read -p "This will create a new Mosquitto user with the provided username and password. Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting user creation."
    exit 0
fi

read -p "Enter the new MQTT username: " MQTT_USERNAME

docker run --rm -it \
  -v "${CONFIG_DIR}:/mosquitto/config" \
  "${IMAGE_NAME}" \
  mosquitto_passwd -c /mosquitto/config/passwd $MQTT_USERNAME


# If mosquitto.conf doesn't exist, create a default one
if [ ! -f "${CONFIG_DIR}/mosquitto.conf" ]; then
    cp ./default_mosquitto.conf "${CONFIG_DIR}/mosquitto.conf"
    echo "Default mosquitto.conf created at ${CONFIG_DIR}/mosquitto.conf"
fi

mkdir -p ./local
touch "${INIT_FLAG}"
