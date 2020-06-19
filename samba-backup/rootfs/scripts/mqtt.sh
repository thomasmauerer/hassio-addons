#!/usr/bin/env bashio

declare MQTT_SUPPORT=false
declare MQTT_TOPIC="samba_backup/status"
declare MQTT_STATUS=(IDLE RUNNING SUCCEEDED FAILED)


# ------------------------------------------------------------------------------
# Configure mosquitto_pub.
# ------------------------------------------------------------------------------
function setup-mqtt {
    local host
    local username
    local password
    local port

    if bashio::services.available "mqtt"; then
        host=$(bashio::services "mqtt" "host")
        username=$(bashio::services "mqtt" "username")
        password=$(bashio::services "mqtt" "password")
        port=$(bashio::services "mqtt" "port")

        mkdir -p $HOME/.config
        {
            echo "-h ${host}"
            echo "--username ${username}"
            echo "--pw ${password}"
            echo "--port ${port}"
        } > $HOME/.config/mosquitto_pub

        MQTT_SUPPORT=true
        bashio::log.info "Mqtt notifications are published on topic \"${MQTT_TOPIC}\""
    else
        bashio::log.warning "Mqtt broker not found. Notifications are disabled."
    fi
}

# ------------------------------------------------------------------------------
# Publish status on mqtt.
#
# Arguments:
#  $1 Status to publish
# ------------------------------------------------------------------------------
function publish-status {
    local status="$1"
    [ "$MQTT_SUPPORT" = true ] && mosquitto_pub -r -t "$MQTT_TOPIC" -m "$status" || return 0
}
