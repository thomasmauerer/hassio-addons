#!/command/with-contenv bashio
# shellcheck shell=bash

declare SAMBA_STATUS=(IDLE RUNNING SUCCEEDED FAILED)
declare SENSOR_NAME="sensor.samba_backup"
declare SENSOR_URL="/core/api/states/${SENSOR_NAME}"
declare STORAGE_FILE="/backup/.samba_backup.sensor"

declare CURRENT_STATUS

declare BACKUPS_LOCAL="0"
declare BACKUPS_REMOTE="0"
declare TOTAL_SUCCESS="0"
declare TOTAL_FAIL="0"
declare LAST_BACKUP="never"


# ------------------------------------------------------------------------------
# Get the current sensor values and store them in internal variables.
# ------------------------------------------------------------------------------
function get-sensor {
    local storage
    local result

    if [ -f "$STORAGE_FILE" ]; then
        storage=$(cat "$STORAGE_FILE")

        if result=$(echo "$storage" | jq -r ".attributes.backups_local" 2>/dev/null); then
            [[ "$result" != null ]] && BACKUPS_LOCAL="$result"
        fi

        if result=$(echo "$storage" | jq -r ".attributes.backups_remote" 2>/dev/null); then
            [[ "$result" != null ]] && BACKUPS_REMOTE="$result"
        fi

        if result=$(echo "$storage" | jq -r ".attributes.total_backups_succeeded" 2>/dev/null); then
            [[ "$result" != null ]] && TOTAL_SUCCESS="$result"
        fi

        if result=$(echo "$storage" | jq -r ".attributes.total_backups_failed" 2>/dev/null); then
            [[ "$result" != null ]] && TOTAL_FAIL="$result"
        fi

        if result=$(echo "$storage" | jq -r ".attributes.last_backup" 2>/dev/null); then
            [[ "$result" != null ]] && LAST_BACKUP="$result"
        fi
    fi

    bashio::log.debug "Backups local/remote: ${BACKUPS_LOCAL}/${BACKUPS_REMOTE}"
    bashio::log.debug "Total backups succeeded/failed: ${TOTAL_SUCCESS}/${TOTAL_FAIL}"
    bashio::log.debug "Last backup: ${LAST_BACKUP}"

    return 0
}

# ------------------------------------------------------------------------------
# Update the Home Assistant sensor.
#
# Arguments
#  $1 The status
#  $2 Whether to update all values
# ------------------------------------------------------------------------------
function update-sensor {
    local status=${1}
    local all=${2:-}
    local data
    local response

    CURRENT_STATUS="$status"

    if bashio::var.has_value "${all}"; then
        if response=$(ha backups --raw-json | jq ".data.backups[].slug"); then
            [ -n "$response" ] && BACKUPS_LOCAL=$(echo "$response" | wc -l) || BACKUPS_LOCAL="0"
        fi

        if response=$(eval "${SMB} -c 'cd \"${TARGET_DIR}\"; ls'"); then
            # grep returns non-zero exit code if there are no matches
            if response=$(echo "$response" | grep -E '\<([0-9a-f]{8}|Samba_Backup_.*)\.tar\>'); then
                BACKUPS_REMOTE=$(echo "$response" | wc -l)
            else
                BACKUPS_REMOTE="0"
            fi
        fi

        if [ "$CURRENT_STATUS" = "${SAMBA_STATUS[2]}" ]; then
            TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
            LAST_BACKUP=$(date +'%Y-%m-%d %H:%M')
        elif [ "$CURRENT_STATUS" = "${SAMBA_STATUS[3]}" ]; then
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
    fi

    data=$(jq -n \
    --arg s "$CURRENT_STATUS" \
    --arg bl "$BACKUPS_LOCAL" \
    --arg br "$BACKUPS_REMOTE" \
    --arg ts "$TOTAL_SUCCESS" \
    --arg tf "$TOTAL_FAIL" \
    --arg lb "$LAST_BACKUP" \
    '{
        "state": $s,
        "attributes": {
            "friendly_name": "Samba Backup",
            "backups_local": $bl,
            "backups_remote": $br,
            "total_backups_succeeded": $ts,
            "total_backups_failed": $tf,
            "last_backup": $lb
        }
    }')

    if ! response=$(ha-post-sensor "$data"); then
        bashio::log.error "Unable to update sensor ${SENSOR_NAME} in Home Assistant"
    fi

    echo "$data" > "$STORAGE_FILE"
    return 0
}

# ------------------------------------------------------------------------------
# Restore the Home Assistant sensor with the last known values.
# ------------------------------------------------------------------------------
function restore-sensor {
    local data
    local response

    if [ -f "$STORAGE_FILE" ]; then
        data=$(cat "$STORAGE_FILE")

        if ! response=$(ha-post-sensor "$data"); then
            bashio::log.error "Unable to restore sensor ${SENSOR_NAME} in Home Assistant"
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Reset the counter variables of the Home Assistant sensor.
# ------------------------------------------------------------------------------
function reset-counter {
    TOTAL_SUCCESS="0"
    TOTAL_FAIL="0"

    update-sensor "$CURRENT_STATUS"
    return 0
}


# ------------------------------------------------------------------------------
# ----------------------- INTERNAL FUNCTION ------------------------------------
# ------------------------------------------------------------------------------
# Post a sensor via the REST API of Home Assistant.
#
# Arguments:
#   $1 The JSON data to POST
# ------------------------------------------------------------------------------
function ha-post-sensor {
    local data=${1}
    local status
    local response

    bashio::log.debug "Posting sensor data to API at ${SENSOR_URL}"

    if ! response=$(curl --silent --show-error \
        --write-out '\n%{http_code}' --request "POST" \
        -H "Authorization: Bearer ${__BASHIO_SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${data}" \
        "${__BASHIO_SUPERVISOR_API}${SENSOR_URL}"
    ); then
        bashio::log.debug "${response}"
        bashio::log.error "Something went wrong contacting the API"
        return 1
    fi

    status=${response##*$'\n'}
    response=${response%$status}

    bashio::log.debug "API Status: ${status}"
    bashio::log.debug "API Response: ${response}"

    if [[ "${status}" -eq 401 ]]; then
        bashio::log.error "Unable to authenticate with the API, permission denied"
        return 1
    fi

    echo "${response}"
    return 0
}
