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

echo "Host: ${HOST}"
echo "Share: ${SHARE}"
echo "Target Dir: ${TARGET_DIR}"
echo "Keep local: ${KEEP_LOCAL}"
echo "Keep remote: ${KEEP_REMOTE}"
echo "Trigger time: ${TRIGGER_TIME}"
if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
    SMB="smbclient -U ${USERNAME}%${PASSWORD} //${HOST}/${SHARE}"
else
    SMB="smbclient -N //${HOST}/${SHARE}"
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
    echo "Creating snapshot \"${name}\" ..."
    SLUG="$(ha snapshots new "${args[@]}" --raw-json | jq -r .data.slug).tar"
    echo "Creating snapshot \"${name}\" ... done"
}

function copy-snapshot {
    cd /backup
    echo "Copying snapshot ${SLUG} ..."
    $SMB -c "cd ${TARGET_DIR}; put ${SLUG}"
    echo "Copying snapshot ${SLUG} ... done"
}

function cleanup-snapshots-local {
    snaps=$(ha snapshots --raw-json | jq -c '.data.snapshots[] | {date,slug,name}' | sort -r)
    echo "$snaps"

    echo "$snaps" | tail -n +$(($KEEP_LOCAL + 1)) | while read backup; do
        theslug=$(echo $backup | jq -r .slug)
        echo "Deleting ${theslug} ..."
        ha snapshots remove "$theslug"
        echo "Deleting ${theslug} ... done"
    done
}

function cleanup-snapshots-remote {
    # read all tar files that match the snapshot name pattern and sort them
    input="$($SMB -c "cd ${TARGET_DIR}; ls")"
    snaps="$(echo "$input" | grep -E '\<[0-9a-f]{8}\.tar\>' | while read slug _ _ _ a b c d; do
        theDate=$(echo "$a $b $c $d" | xargs -i date +'%Y-%m-%d %H:%M' -d "{}")
        echo "$theDate $slug"
    done | sort -r)"
    echo "$snaps"

    echo "$snaps" | tail -n +$(($KEEP_REMOTE + 1)) | while read _ _ slug; do
        echo "Deleting ${slug} ..."
        $SMB -c "cd ${TARGET_DIR}; rm ${slug}"
        echo "Deleting ${slug} ... done"
    done
}
###############


#### helper functions ####

function generate-snapshot-name {
    if [ -n "$BACKUP_NAME" ]; then
        # get all values
        theversion=$(ha core info --raw-json | jq -r .data.version_latest)
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

function run-script {
    create-snapshot
    copy-snapshot
    [ "$KEEP_LOCAL" != "all" ] && cleanup-snapshots-local
    [ "$KEEP_REMOTE" != "all" ] && cleanup-snapshots-remote
}
###############


#### main program ####

while true; do
    if [[ "$TRIGGER_TIME" == "manual" ]]; then
        # read from STDIN
        read -r input
        input=$(echo "$input" | jq -r .)
        [[ "$input" == "trigger" ]] && run-script
    else
        # do we have to run it now?
        current_date=$(date +'%a %H:%M')
        [[ "$TRIGGER_DAYS" =~ "${current_date:0:3}" && "$current_date" =~ "$TRIGGER_TIME" ]] && run-script

        sleep 60
    fi
done
###############
