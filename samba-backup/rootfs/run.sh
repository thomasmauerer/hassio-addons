#!/command/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC1091

source scripts/config.sh
source scripts/main.sh
source scripts/helper.sh
source scripts/precheck.sh
source scripts/sensor.sh

export __BASHIO_LOG_TIMESTAMP="%y-%m-%d %T"

function run-backup {
    (
        # synchronize the backup routine
        flock -n -x 200 || { bashio::log.warning "Backup already running. Trigger ignored."; return 0; }

        bashio::log.info "Backup running ..."
        get-sensor
        update-sensor "${SAMBA_STATUS[1]}"

        # run entire backup steps
        # shellcheck disable=SC2015
        create-backup && copy-backup && cleanup-backups-local && cleanup-backups-remote \
            && update-sensor "${SAMBA_STATUS[2]}" "ALL" \
            || update-sensor "${SAMBA_STATUS[3]}" "ALL"

        sleep 10
        update-sensor "${SAMBA_STATUS[0]}"
        bashio::log.info "Backup finished"
    ) 200>/tmp/samba_backup.lockfile
}


# init config and sensor
get-config
get-sensor

# run precheck and exit entire addon in case the check fails
if [ "$SKIP_PRECHECK" = true ]; then
    update-sensor "${SAMBA_STATUS[0]}"
elif ! smb-precheck; then
    update-sensor "${SAMBA_STATUS[3]}"
    exit 1
else
    update-sensor "${SAMBA_STATUS[0]}" "ALL"
fi

bashio::log.info "Samba Backup started successfully"

# check the time in the background
if [[ "$TRIGGER_TIME" != "manual" ]]; then
    {
        bashio::log.debug "Starting main loop ..."
        while true; do
            current_date=$(date +'%a %H:%M')
            [[ "$TRIGGER_DAYS" =~ ${current_date:0:3} && "$current_date" =~ $TRIGGER_TIME ]] && run-backup

            sleep 60
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
        restore-sensor

    elif [ "$input" = "reset-counter" ]; then
        get-sensor && reset-counter
        bashio::log.info "Counter variables reset successfully"

    elif [ "$input" = "trigger" ]; then
        run-backup

    elif is-extended-trigger "$input"; then
        bashio::log.info "Running backup with customized parameters"
        overwrite-params "$input" && run-backup && restore-params

    else
        bashio::log.warning "Received unknown input: ${input}"
    fi
done
