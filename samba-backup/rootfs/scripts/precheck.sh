#!/usr/bin/env bashio

# ------------------------------------------------------------------------------
# Perform a pre-check if the Samba share is configured correctly.
#
# Returns 1 in case of a failure
# ------------------------------------------------------------------------------
function smb-precheck {

    # check if we can access the share at all
    if ! run-and-log "${SMB} -c 'exit'"; then
        bashio::log.fatal "Cannot access share. Please check your config."
        return 1
    fi

    # check if the target directory exists
    if ! run-and-log "${SMB} -c 'cd \"${TARGET_DIR}\"'"; then
        bashio::log.fatal "Target directory does not exist. Please check your config."
        return 1
    fi

    # check if we have write permissions
    touch samba-tmp123
    if ! run-and-log "${SMB} -c 'cd \"${TARGET_DIR}\"; put samba-tmp123; rm samba-tmp123'"; then
        bashio::log.fatal "Missing write permissions on target folder. Please check your share settings."
        return 1
    fi
    rm samba-tmp123

    return 0
}
