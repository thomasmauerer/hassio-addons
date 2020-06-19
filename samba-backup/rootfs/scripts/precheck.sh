#!/usr/bin/env bashio

# ------------------------------------------------------------------------------
# Perform a pre-check if the Samba share is configured correctly.
#
# Exits the entire program in case of a failure
# ------------------------------------------------------------------------------
function smb-precheck {
    # check if we can access the share at all
    run-and-log "${SMB} -c \"exit\"" \
        || { bashio::log.fatal "Cannot access share. Please check your config."; publish-status "${MQTT_STATUS[3]}"; exit 1; }

    # check if the target directory exists
    run-and-log "${SMB} -c \"cd ${TARGET_DIR}\"" \
        || { bashio::log.fatal "Target directory does not exist. Please check your config."; publish-status "${MQTT_STATUS[3]}"; exit 1; }

    # check if we have write permissions
    touch samba-tmp123
    run-and-log "${SMB} -c \"cd ${TARGET_DIR}; put samba-tmp123; rm samba-tmp123\"" \
        || { bashio::log.fatal "Missing write permissions. Please check your share settings."; publish-status "${MQTT_STATUS[3]}"; exit 1; }
    rm samba-tmp123
}
