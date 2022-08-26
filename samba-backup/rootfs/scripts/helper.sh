#!/command/with-contenv bashio
# shellcheck shell=bash

# ------------------------------------------------------------------------------
# Create the backup name by replacing all name patterns.
#
# Returns the final name on stdout
# ------------------------------------------------------------------------------
function generate-backup-name {
    local name
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
    else
        name="Samba Backup $(date +'%Y-%m-%d %H:%M')"
    fi

    echo "$name"
}

# ------------------------------------------------------------------------------
# Create a valid filename by replacing all forbidden characters.
#
# Arguments
#  $1 The original name
#
# Returns the final name on stdout
# ------------------------------------------------------------------------------
function generate-filename {
    local input="${1}"
    local prefix

    declare -a forbidden=('\/' '\\' '\<' '\>' '\:' '\"' '\|' '\?' '\*' '\.' '\..' '\ ' '\-')
    for fc in "${forbidden[@]}"; do
        input=${input//$fc/_}
    done

    prefix=${input:0:13}
    [ "$prefix" = "Samba_Backup_" ] && echo "${input}" || echo "Samba_Backup_${input}"
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

    if result=$(eval "$cmd"); then
        [ -n "$result" ] && bashio::log.debug "$result"
    else
        bashio::log.warning "$result"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Checks if input is an extended trigger.
#
# Arguments
#  $1 The input to check
#
# Returns 0 (true) or 1 (false)
# ------------------------------------------------------------------------------
function is-extended-trigger {
    local input=${1}
    local cmd

    if cmd=$(echo "$input" | jq -r '.command' 2>/dev/null); then
        [ "$cmd" = "trigger" ] && return 0
    fi

    return 1
}
