#!/usr/bin/env bashio

source scripts/config.sh
source scripts/mqtt.sh
source scripts/main.sh
source scripts/helper.sh
source scripts/precheck.sh


function run-backup {
    (
        # synchronize the backup routine -> only one shell allowed
        flock -n -x 200 || { bashio::log.warning "Backup already running. Trigger ignored."; return 0; }

        bashio::log.info "Backup running ..."
        publish-status "${MQTT_STATUS[1]}"

        # run entire backup steps
        create-snapshot && copy-snapshot && cleanup-snapshots-local && cleanup-snapshots-remote \
            && { publish-status "${MQTT_STATUS[2]}"; sleep 10; } \
            || { publish-status "${MQTT_STATUS[3]}"; exit 1; }

        bashio::log.info "Backup finished"
        publish-status "${MQTT_STATUS[0]}"
    ) 200>/tmp/samba_backup.lockfile
}


# read in user config
get-config

# setup mqtt
setup-mqtt
publish-status "${MQTT_STATUS[0]}"

# run precheck (will exit on failure)
smb-precheck

# run the main loop in a parallel subshell
(
    bashio::log.debug "Starting main loop ..."
    while true; do
        if [[ "$TRIGGER_TIME" != "manual" ]]; then
            # check if we have to run
            current_date=$(date +'%a %H:%M')
            [[ "$TRIGGER_DAYS" =~ "${current_date:0:3}" && "$current_date" =~ "$TRIGGER_TIME" ]] && run-backup
        fi

        sleep 60
    done
) &

# start the STDIN listener --> must be running on main shell
bashio::log.debug "Starting STDIN listener ..."
while true; do
    read -r input
    bashio::log.debug "Input read: ${input}"
    input=$(echo "$input" | jq -r .)
    [[ "$input" == "trigger" ]] && run-backup
done
