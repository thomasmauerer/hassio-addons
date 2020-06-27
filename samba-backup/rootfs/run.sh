#!/usr/bin/env bashio

source scripts/config.sh
source scripts/mqtt.sh
source scripts/main.sh
source scripts/helper.sh
source scripts/precheck.sh


function run-backup {
    bashio::log.info "Backup running ..."
    publish-status "${MQTT_STATUS[1]}"

    # run entire backup steps
    create-snapshot && copy-snapshot && cleanup-snapshots-local && cleanup-snapshots-remote \
        && { publish-status "${MQTT_STATUS[2]}"; sleep 10; } \
        || { publish-status "${MQTT_STATUS[3]}"; exit 1; }

    bashio::log.info "Backup finished"
    publish-status "${MQTT_STATUS[0]}"
}


# read in user config
get-config

# setup mqtt
setup-mqtt
publish-status "${MQTT_STATUS[0]}"

# run precheck (will exit on failure)
smb-precheck

# run program loop
while true; do
    current_date=$(date +'%a %H:%M')
    # do we have to run it now?
    if [[ "$TRIGGER_DAYS" =~ "${current_date:0:3}" && "$current_date" =~ "$TRIGGER_TIME" ]]; then
        run-backup
    else
        # read from STDIN
        read -r input
        input=$(echo "$input" | jq -r .)
        [[ "$input" == "trigger" ]] && run-backup
    fi
    sleep 60
done
