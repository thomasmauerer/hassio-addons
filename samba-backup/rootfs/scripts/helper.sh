#!/usr/bin/env bashio

# ------------------------------------------------------------------------------
# Create the snapshot name by replacing all name patterns.
#
# Returns the final name on stdout
# ------------------------------------------------------------------------------
function generate-snapshot-name {
    local name="Samba Backup $(date +'%Y-%m-%d %H:%M')"
    local theversion
    local thetype
    local thedate

    if [ -n "$BACKUP_NAME" ]; then
        # get all values
        theversion=$(ha core info --raw-json | jq -r .data.version)
        [[ -n "$EXCLUDE_ADDONS" || -n "$EXCLUDE_FOLDERS" ]] && thetype="Partial" || thetype="Full"
        thedate=$(date +'%Y-%m-%d %H:%M')

        # replace the string patterns with the real values
        name="$BACKUP_NAME"
        name=${name/\{version\}/$theversion}
        name=${name/\{type\}/$thetype}
        name=${name/\{date\}/$thedate}
    fi

    echo "$name"
}

# ------------------------------------------------------------------------------
# Run a command and log its output (debug or warning).
#
# Arguments
#  $1 The command to run
#
# Returns 1 in case the command failed
# ------------------------------------------------------------------------------
function run-and-log {
    local cmd="$1"
    local result

    result=$(eval "$cmd") \
        && bashio::log.debug "$result" \
        || { bashio::log.warning "$result"; return 1; }
}
