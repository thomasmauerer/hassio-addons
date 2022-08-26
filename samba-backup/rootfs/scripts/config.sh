#!/command/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2034

# user input variables
declare TARGET_DIR
declare KEEP_LOCAL
declare KEEP_REMOTE
declare TRIGGER_TIME
declare TRIGGER_DAYS
declare EXCLUDE_ADDONS
declare EXCLUDE_FOLDERS
declare BACKUP_NAME
declare BACKUP_PWD
declare SKIP_PRECHECK


# smbclient command strings
declare SMB
declare ALL_SHARES


# ------------------------------------------------------------------------------
# Read and print config.
# ------------------------------------------------------------------------------
function get-config {
    local host
    local share
    local username
    local password
    local workgroup

    host=$(bashio::config 'host' | escape-input)
    share=$(bashio::config 'share' | escape-input)
    username=$(bashio::config 'username' | escape-input)
    password=$(bashio::config 'password' | escape-input)
    bashio::config.exists 'workgroup' && workgroup=$(bashio::config 'workgroup' | escape-input) || workgroup=""

    TARGET_DIR=$(bashio::config 'target_dir')
    KEEP_LOCAL=$(bashio::config 'keep_local')
    KEEP_REMOTE=$(bashio::config 'keep_remote')
    TRIGGER_TIME=$(bashio::config 'trigger_time')
    TRIGGER_DAYS=$(bashio::config 'trigger_days')
    EXCLUDE_ADDONS=$(bashio::config 'exclude_addons')
    EXCLUDE_FOLDERS=$(bashio::config 'exclude_folders')

    bashio::config.exists 'backup_name' && BACKUP_NAME=$(bashio::config 'backup_name') || BACKUP_NAME=""
    bashio::config.exists 'backup_password' && BACKUP_PWD=$(bashio::config 'backup_password') || BACKUP_PWD=""
    bashio::config.true 'skip_precheck' && SKIP_PRECHECK=true || SKIP_PRECHECK=false

    if [[ -n "$username" && -n "$password" ]]; then
        SMB="smbclient -U \"${username}\"%\"${password}\" \"//${host}/${share}\" 2>&1 -t 180"
        ALL_SHARES="smbclient -U \"${username}\"%\"${password}\" -L \"//${host}\" 2>&1"
    else
        SMB="smbclient -N \"//${host}/${share}\" 2>&1 -t 180"
        ALL_SHARES="smbclient -N -L \"//${host}\" 2>&1"
    fi

    # non-default workgroup?
    [ -n "$workgroup" ] && SMB="${SMB} -W \"${workgroup}\""
    [ -n "$workgroup" ] && ALL_SHARES="${ALL_SHARES} -W \"${workgroup}\""

    # legacy SMB protocols allowed?
    bashio::config.true 'compatibility_mode' && SMB="${SMB} --option=\"client min protocol\"=\"NT1\""
    bashio::config.true 'compatibility_mode' && ALL_SHARES="${ALL_SHARES} --option=\"client min protocol\"=\"NT1\""

    bashio::log.info "---------------------------------------------------"
    bashio::log.info "Host/Share: ${host}/${share}"
    bashio::log.info "Target directory: ${TARGET_DIR}"
    bashio::log.info "Keep local/remote: ${KEEP_LOCAL}/${KEEP_REMOTE}"
    bashio::log.info "Trigger time: ${TRIGGER_TIME}"
    [[ "$TRIGGER_TIME" != "manual" ]] && bashio::log.info "Trigger days: $(echo "$TRIGGER_DAYS" | xargs)"
    bashio::log.info "---------------------------------------------------"

    return 0
}

# ------------------------------------------------------------------------------
# Escape input given by the user.
#
# Returns the escaped string on stdout
# ------------------------------------------------------------------------------
function escape-input {
    local input
    read -r input

    # escape the evil dollar sign
    input=${input//$/\\$}

    echo "$input"
}

# ------------------------------------------------------------------------------
# Overwrite the backup parameters.
#
# Arguments
#  $1 The json input string
# ------------------------------------------------------------------------------
function overwrite-params {
    local input="$1"
    local addons
    local folders
    local name
    local password

    addons=$(echo "$input" | jq '.exclude_addons[]' 2>/dev/null)
    [[ "$addons" != null  ]] && EXCLUDE_ADDONS="$addons"

    folders=$(echo "$input" | jq '.exclude_folders[]' 2>/dev/null)
    [[ "$folders" != null  ]] && EXCLUDE_FOLDERS="$folders"

    name=$(echo "$input" | jq -r '.backup_name')
    [[ "$name" != null  ]] && BACKUP_NAME="$name"

    password=$(echo "$input" | jq -r '.backup_password')
    [[ "$password" != null  ]] && BACKUP_PWD="$password"

    return 0
}

# ------------------------------------------------------------------------------
# Restore the original backup parameters.
# ------------------------------------------------------------------------------
function restore-params {
    EXCLUDE_ADDONS=$(bashio::config 'exclude_addons')
    EXCLUDE_FOLDERS=$(bashio::config 'exclude_folders')
    bashio::config.exists 'backup_name' && BACKUP_NAME=$(bashio::config 'backup_name') || BACKUP_NAME=""
    bashio::config.exists 'backup_password' && BACKUP_PWD=$(bashio::config 'backup_password') || BACKUP_PWD=""

    return 0
}
