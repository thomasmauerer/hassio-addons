#!/usr/bin/env bashio

declare MQTT_SUPPORT=false
declare MQTT_STATUS=(IDLE RUNNING SUCCEEDED FAILED)


# ------------------------------------------------------------------------------
# Configure mosquitto_pub.
# ------------------------------------------------------------------------------
function setup-mqtt {
    local host
    local username
    local password
    local port

    if [ -n "$MQTT_HOST" ]; then
        mkdir -p $HOME/.config
        {
            echo "-h ${MQTT_HOST}"
            [ -n "$MQTT_USERNAME" ] && echo "--username ${MQTT_USERNAME}"
            [ -n "$MQTT_PASSWORD" ] && echo "--pw ${MQTT_PASSWORD}"
            [ -n "$MQTT_PORT" ] && echo "--port ${MQTT_PORT}"
        } > $HOME/.config/mosquitto_pub

        MQTT_SUPPORT=true
        bashio::log.info "Using mqtt configuration for \"${MQTT_HOST}\" - topic is \"${MQTT_TOPIC}/#\""

    elif bashio::services.available "mqtt"; then
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
        bashio::log.info "Found local mqtt broker - topic is \"${MQTT_TOPIC}/#\""

    else
        bashio::log.warning "No Mqtt broker found. Notifications are disabled."
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
    [ "$MQTT_SUPPORT" = true ] && mosquitto_pub -r -t "$MQTT_TOPIC/status" -m "$status" || return 0
}
