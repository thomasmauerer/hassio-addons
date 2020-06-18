#!/usr/bin/env bashio

#### config ####

HOST=$(bashio::config 'host')
SHARE=$(bashio::config 'share')
TARGET_DIR=$(bashio::config 'target_dir')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
KEEP_LOCAL=$(bashio::config 'keep_local')
KEEP_REMOTE=$(bashio::config 'keep_remote')
TRIGGER_TIME=$(bashio::config 'trigger_time')
TRIGGER_DAYS=$(bashio::config 'trigger_days')
EXCLUDE_ADDONS=$(bashio::config 'exclude_addons')
EXCLUDE_FOLDERS=$(bashio::config 'exclude_folders')
BACKUP_NAME=$(bashio::config 'backup_name')
BACKUP_PWD=$(bashio::config 'backup_password')
bashio::config.exists 'log_level' && LOG_LEVEL=$(bashio::config 'log_level') || LOG_LEVEL="info"

if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
    SMB="smbclient -U ${USERNAME}%${PASSWORD} //${HOST}/${SHARE} 2>&1"
else
    SMB="smbclient -N //${HOST}/${SHARE} 2>&1"
fi

###############


#### main functions ####

function create-snapshot {
    name=$(generate-snapshot-name)

    # prepare args
    args=()

    args+=("--name" "$name")
    [ -n "$BACKUP_PWD" ] && args+=("--password" "$BACKUP_PWD")

    # do we need a partial backup?
    if [[ -n "$EXCLUDE_ADDONS" || -n "$EXCLUDE_FOLDERS" ]]; then
        # include all installed addons that are not listed to be excluded
        addons=$(ha addons --raw-json | jq -rc '.data.addons[] | select (.installed != null) | .slug')
        for ad in ${addons}; do [[ ! $EXCLUDE_ADDONS =~ "$ad" ]] && args+=("-a" "$ad"); done

        # include all folders that are not listed to be excluded
        folders=(homeassistant ssl share addons/local)
        for fol in ${folders[@]}; do [[ ! $EXCLUDE_FOLDERS =~ "$fol" ]] && args+=("-f" "$fol"); done
    fi

    # run the command
    bashio::log.info "Creating snapshot \"${name}\""
    SLUG="$(ha snapshots new "${args[@]}" --raw-json | jq -r .data.slug).tar"
}

function copy-snapshot {
    cd /backup
    bashio::log.info "Copying snapshot ${SLUG} to share"
    run-and-log "${SMB} -c \"cd ${TARGET_DIR}; put ${SLUG}\""
}

function cleanup-snapshots-local {
    snaps=$(ha snapshots --raw-json | jq -c '.data.snapshots[] | {date,slug,name}' | sort -r)
    bashio::log.debug "$snaps"

    echo "$snaps" | tail -n +$(($KEEP_LOCAL + 1)) | while read backup; do
        theslug=$(echo $backup | jq -r .slug)
        bashio::log.info "Deleting ${theslug} local"
        run-and-log "ha snapshots remove ${theslug}"
    done
}

function cleanup-snapshots-remote {
    # read all tar files that match the snapshot name pattern and sort them
    input="$($SMB -c "cd ${TARGET_DIR}; ls")"
    snaps="$(echo "$input" | grep -E '\<[0-9a-f]{8}\.tar\>' | while read slug _ _ _ a b c d; do
        theDate=$(echo "$a $b $c $d" | xargs -i date +'%Y-%m-%d %H:%M' -d "{}")
        echo "$theDate $slug"
    done | sort -r)"
    bashio::log.debug "$snaps"

    echo "$snaps" | tail -n +$(($KEEP_REMOTE + 1)) | while read _ _ slug; do
        bashio::log.info "Deleting ${slug} on share"
        run-and-log "${SMB} -c \"cd ${TARGET_DIR}; rm ${slug}\""
    done
}

###############


#### helper functions ####

function generate-snapshot-name {
    if [ -n "$BACKUP_NAME" ]; then
        # get all values
        theversion=$(ha core info --raw-json | jq -r .data.version)
        [[ -n "$EXCLUDE_ADDONS" || -n "$EXCLUDE_FOLDERS" ]] && thetype="Partial" || thetype="Full"
        thedate=$(date +'%Y-%m-%d %H:%M')

        # replace the string patterns with the real values
        name=$BACKUP_NAME
        name=${name/\{version\}/$theversion}
        name=${name/\{type\}/$thetype}
        name=${name/\{date\}/$thedate}
    else
        name="Samba Backup $(date +'%Y-%m-%d %H:%M')"
    fi

    echo "$name"
}

function run-and-log {
    local cmd="$1"
    local result
    result=$(eval "$cmd") && bashio::log.debug "$result" || { bashio::log.warning "$result"; return 1; }
}

function smb-precheck {
    # check if we can access the share at all
    run-and-log "${SMB} -c \"exit\"" || { bashio::log.error "Cannot access share. Please check your config."; exit 1; }

    # check if the target directory exists
    run-and-log "${SMB} -c \"cd ${TARGET_DIR}\"" || { bashio::log.error "Target directory does not exist. Please check your config."; exit 1; }

    # check if we have write permissions
    run-and-log "${SMB} -c \"cd ${TARGET_DIR}; mkdir samba-tmp123; rmdir samba-tmp123\"" || { bashio::log.error "Missing write permissions. Please check your share settings."; exit 1; }
}

###############


#### main program ####

function run-backup {
    bashio::log.info "Backup running ..."
    create-snapshot
    copy-snapshot
    [ "$KEEP_LOCAL" != "all" ] && cleanup-snapshots-local
    [ "$KEEP_REMOTE" != "all" ] && cleanup-snapshots-remote
    bashio::log.info "Backup finished"
}

# perform setup stuff
bashio::log.level "$LOG_LEVEL"

bashio::log.info "Host: ${HOST}"
bashio::log.info "Share: ${SHARE}"
bashio::log.info "Target Dir: ${TARGET_DIR}"
bashio::log.info "Keep local: ${KEEP_LOCAL}"
bashio::log.info "Keep remote: ${KEEP_REMOTE}"
bashio::log.info "Trigger time: ${TRIGGER_TIME}"
[[ "$TRIGGER_TIME" != "manual" ]] && bashio::log.info "Trigger days: $(echo "$TRIGGER_DAYS" | xargs)"


# run precheck (will exit on failure)
smb-precheck


# run loop
while true; do
    if [[ "$TRIGGER_TIME" == "manual" ]]; then
        # read from STDIN
        read -r input
        input=$(echo "$input" | jq -r .)
        [[ "$input" == "trigger" ]] && run-backup
    else
        # do we have to run it now?
        current_date=$(date +'%a %H:%M')
        [[ "$TRIGGER_DAYS" =~ "${current_date:0:3}" && "$current_date" =~ "$TRIGGER_TIME" ]] && run-backup

        sleep 60
    fi
done

###############
