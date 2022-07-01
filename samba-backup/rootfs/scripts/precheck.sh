#!/command/with-contenv bashio
# shellcheck shell=bash

# ------------------------------------------------------------------------------
# Perform a pre-check if the Samba share is configured correctly.
#
# Returns 1 in case of a failure
# ------------------------------------------------------------------------------
function smb-precheck {
    local result
    local shares

    # check if we can access the share at all
    if ! result=$(eval "${SMB} -c 'exit'"); then
        bashio::log.warning "$result"

        # host unreachable
        if [[ "$result" =~ "NT_STATUS_HOST_UNREACHABLE" ]]; then
            bashio::log.fatal "The provided host is unreachable. Please check your config and network."

        # SMB1 problem
        elif [[ "$result" =~ "NT_STATUS_CONNECTION_DISCONNECTED" ]]; then
            bashio::log.fatal "Cannot access share. It seems that your share only supports insecure SMB protocols."
            bashio::log.fatal "If you want me to connect, please check the \"compatibility_mode\" option. Use at your own risk."

        # share does not exist
        elif [[ "$result" =~ "NT_STATUS_BAD_NETWORK_NAME" ]]; then
            bashio::log.fatal "Cannot access share. It seems that your configured share does not exist."

            # try to find out which shares exist
            if shares=$(eval "${ALL_SHARES}"); then
                bashio::log.fatal "I found the following shares on your host. Did you mean one of those?"
                bashio::log.fatal "$shares"
            fi

        # access denied
        elif [[ "$result" =~ "NT_STATUS_ACCESS_DENIED" ]]; then
            bashio::log.fatal "Cannot access share. Access denied. Please check your share permissions."

        # login failed
        elif [[ "$result" =~ "NT_STATUS_LOGON_FAILURE" ]]; then
            bashio::log.fatal "Cannot access share. Login failed. Please check your credentials."

        # unknown reason
        else
            bashio::log.fatal "Cannot access share. Unknown reason."
        fi

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
