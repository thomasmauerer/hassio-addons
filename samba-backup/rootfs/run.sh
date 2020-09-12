#!/usr/bin/env bashio

source scripts/config.sh
source scripts/mqtt.sh
source scripts/main.sh
source scripts/helper.sh
source scripts/precheck.sh
source scripts/sensor.sh


function run-backup {
    (
        # synchronize the backup routine
        flock -n -x 200 || { bashio::log.warning "Backup already running. Trigger ignored."; return 0; }

        bashio::log.info "Backup running ..."
        publish-status "${MQTT_STATUS[1]}"
        get-sensor
        update-sensor "${SAMBA_STATUS[1]}"

        # run entire backup steps
        create-snapshot && copy-snapshot && cleanup-snapshots-local && cleanup-snapshots-remote \
            && { publish-status "${MQTT_STATUS[2]}"; update-sensor "${SAMBA_STATUS[2]}" "ALL"; } \
            || { publish-status "${MQTT_STATUS[3]}"; update-sensor "${SAMBA_STATUS[3]}" "ALL"; }

        sleep 10
        publish-status "${MQTT_STATUS[0]}"
        update-sensor "${SAMBA_STATUS[0]}"
        bashio::log.info "Backup finished"
    ) 200>/tmp/samba_backup.lockfile
}


# read in user config
get-config

# setup mqtt
setup-mqtt
publish-status "${MQTT_STATUS[0]}"

# setup Home Assistant sensor
get-sensor
update-sensor "${SAMBA_STATUS[0]}"

# run precheck and exit entire addon
if ! smb-precheck; then
    publish-status "${MQTT_STATUS[3]}"
    update-status "${SAMBA_STATUS[3]}"
    exit 1
fi


# check the time in the background
if [[ "$TRIGGER_TIME" != "manual" ]]; then
    {
        bashio::log.debug "Starting main loop ..."
        while true; do
            current_date=$(date +'%a %H:%M')
            [[ "$TRIGGER_DAYS" =~ "${current_date:0:3}" && "$current_date" =~ "$TRIGGER_TIME" ]] && run-backup

            sleep 60
        done
    } &
fi

# start the mqtt listener in background
if [ "$MQTT_SUPPORT" = true ]; then
    {
        bashio::log.debug "Starting mqtt listener on ${MQTT_TOPIC}/trigger ..."
        while true; do
            mqtt_input=$(mosquitto_sub -t "$MQTT_TOPIC/trigger" -C 1)
            bashio::log.debug "Mqtt message received: ${mqtt_input}"

            if [[ "$mqtt_input" == "trigger" ]]; then
                run-backup
            elif is-extended-trigger "$mqtt_input"; then
                bashio::log.info "Running backup with customized parameters"
                overwrite-params "$mqtt_input" && run-backup && restore-params
            fi
        done
    } &
fi

# start the stdin listener in foreground
bashio::log.debug "Starting stdin listener ..."
while true; do
    read -r input
    bashio::log.debug "Input received: ${input}"
    input=$(echo "$input" | jq -r .)

    if [ "$input" = "restore-sensor" ]; then
        (
            flock -n -x 200 && restore-sensor || bashio::log.warning "Backup is running. Restore-Sensor not possible."
        ) 200>/tmp/samba_backup.lockfile

    elif [ "$input" = "trigger" ]; then
        run-backup

    elif is-extended-trigger "$input"; then
        bashio::log.info "Running backup with customized parameters"
        overwrite-params "$input" && run-backup && restore-params

    else
        bashio::log.warning "Received unknown input: ${input}"
    fi
done
