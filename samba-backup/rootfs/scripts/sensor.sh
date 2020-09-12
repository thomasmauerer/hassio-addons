#!/usr/bin/env bashio

declare SAMBA_STATUS=(IDLE RUNNING SUCCEEDED FAILED)
declare SENSOR_NAME="sensor.samba_backup"
declare SENSOR_URL="/core/api/states/${SENSOR_NAME}"

declare CURRENT_STATUS

declare BACKUPS_LOCAL="0"
declare BACKUPS_REMOTE="0"
declare TOTAL_SUCCESS="0"
declare TOTAL_FAIL="0"
declare LAST_BACKUP="never"


# ------------------------------------------------------------------------------
# Get the current sensor information from Home Assistant.
# ------------------------------------------------------------------------------
function get-current-sensor {
    local response
    local result

    # get the current sensor attributes
    if response=$(ha-api GET "$SENSOR_URL"); then

        if result=$(echo "$response" | jq -r ".attributes.backups_local" 2>/dev/null); then
            [[ "$result" != null ]] && BACKUPS_LOCAL="$result"
        fi

        if result=$(echo "$response" | jq -r ".attributes.backups_remote" 2>/dev/null); then
            [[ "$result" != null ]] && BACKUPS_REMOTE="$result"
        fi

        if result=$(echo "$response" | jq -r ".attributes.total_backups_succeeded" 2>/dev/null); then
            [[ "$result" != null ]] && TOTAL_SUCCESS="$result"
        fi

        if result=$(echo "$response" | jq -r ".attributes.total_backups_failed" 2>/dev/null); then
            [[ "$result" != null ]] && TOTAL_FAIL="$result"
        fi

        if result=$(echo "$response" | jq -r ".attributes.last_backup" 2>/dev/null); then
            [[ "$result" != null ]] && LAST_BACKUP="$result"
        fi

    fi

    bashio::log.debug "Backups local: ${BACKUPS_LOCAL}"
    bashio::log.debug "Backups remote: ${BACKUPS_REMOTE}"
    bashio::log.debug "Total backups succeeded: ${TOTAL_SUCCESS}"
    bashio::log.debug "Total backups failed: ${TOTAL_FAIL}"
    bashio::log.debug "Last backup: ${LAST_BACKUP}"

    return 0
}

# ------------------------------------------------------------------------------
# Update the status only.
#
# Arguments
#  $1 The status
# ------------------------------------------------------------------------------
function update-status {
    local data
    local response

    CURRENT_STATUS="$1"
    data=$(create-sensor-data)

    if ! response=$(ha-api POST "$SENSOR_URL" "$data"); then
        bashio::log.error "Unable to update sensor ${SENSOR_NAME} in Home Assistant"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Update entire sensor including attributes.
#
# Arguments
#  $1 The status
# ------------------------------------------------------------------------------
function update-sensor {
    local data
    local response

    CURRENT_STATUS="$1"

    if response=$(ha snapshots --raw-json | jq ".data.snapshots[].slug"); then
        BACKUPS_LOCAL=$(echo "$response" | wc -l)
    fi

    if response=$(eval "${SMB} -c 'cd \"${TARGET_DIR}\"; ls'"); then
        BACKUPS_REMOTE=$(echo "$response" | grep -E '\<[0-9a-f]{8}\.tar\>' | wc -l)
    fi

    if [ "$CURRENT_STATUS" = ${SAMBA_STATUS[2]} ]; then
        TOTAL_SUCCESS=$(($TOTAL_SUCCESS + 1))
        LAST_BACKUP=$(date +'%Y-%m-%d %H:%M')
    elif [ "$CURRENT_STATUS" = ${SAMBA_STATUS[3]} ]; then
        TOTAL_FAIL=$(($TOTAL_FAIL + 1))
    fi

    data=$(create-sensor-data)

    if ! response=$(ha-api POST "$SENSOR_URL" "$data"); then
        bashio::log.error "Unable to update sensor ${SENSOR_NAME} in Home Assistant"
    fi

    return 0
}


# ------------------------------------------------------------------------------
# Create json data for the sensor.
#
# Returns the json string on stdout.
# ------------------------------------------------------------------------------
function create-sensor-data {
    local data=$(jq -n \
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

    echo "$data"
}

# ------------------------------------------------------------------------------
# Make a call to the REST API of Home Assistant.
#
# Arguments:
#   $1 HTTP Method (GET/POST)
#   $2 API Resource requested
#   $3 In case of a POST method, this parameter is the JSON to POST
# ------------------------------------------------------------------------------
function ha-api {
    local method=${1}
    local resource=${2}
    local jsonData=${3:-}
    local data='{}'
    local response
    local status

    if [[ "${method}" = "POST" ]] && bashio::var.has_value "${jsonData}"; then
        data="${jsonData}"
    fi

    if ! response=$(curl --silent --show-error \
        --write-out '\n%{http_code}' --request "${method}" \
        -H "Authorization: Bearer ${__BASHIO_SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${data}" \
        "${__BASHIO_SUPERVISOR_API}${resource}"
    ); then
        bashio::log.debug "${response}"
        bashio::log.error "Something went wrong contacting the API"
        return 1
    fi

    status=${response##*$'\n'}
    response=${response%$status}

    bashio::log.debug "API Request: ${method} ${resource}"
    bashio::log.debug "API Status: ${status}"
    bashio::log.debug "API Response: ${response}"

    if [[ "${status}" -eq 401 ]]; then
        bashio::log.error "Unable to authenticate with the API, permission denied"
        return 1
    fi

    echo "${response}"
    return 0
}