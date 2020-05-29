#!/usr/bin/env bashio

#### config ####

HOST=$(bashio::config 'host')
SHARE=$(bashio::config 'share')
TARGET_DIR=$(bashio::config 'target_dir')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
KEEP_LOCAL=$(bashio::config 'keep_local')
KEEP_REMOTE=$(bashio::config 'keep_remote')
BACKUP_PWD=$(bashio::config 'backup_password')
EXCLUDE_ADDONS=$(bashio::config 'exclude_addons')
EXCLUDE_FOLDERS=$(bashio::config 'exclude_folders')

echo "Host: ${HOST}"
echo "Share: ${SHARE}"
echo "Target Dir: ${TARGET_DIR}"
if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    echo "Username: ***"
    SMB="smbclient -U ${USERNAME}%${PASSWORD} //${HOST}/${SHARE}"
else
    echo "Username: guest mode"
    SMB="smbclient -N //${HOST}/${SHARE}"
fi
echo "Keep local: ${KEEP_LOCAL}"
echo "Keep remote: ${KEEP_REMOTE}"
###############


#### functions ####

function create-snapshot {
    name="Automatic Backup $(date +'%Y-%m-%d %H:%M')"

    # prepare args
    args=()

    args+=("--name" "$name")
    [ -n "$BACKUP_PWD" ] && args+=("--password" "$BACKUP_PWD")

    # do we need a partial backup?
    if [ -n "$EXCLUDE_ADDONS" ] || [ -n "$EXCLUDE_FOLDERS" ]; then
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
    snaps=$(ha snapshots --raw-json | jq -c '.data.snapshots[] | {date,slug,name} | select(.name | contains("Automatic Backup"))' | sort -r)
    echo "$snaps"

    i="1"
    echo "$snaps" | while read backup; do
        if [ -z "$KEEP_LOCAL" ] || [ "$i" -gt "$KEEP_LOCAL" ]; then
            theslug=$(echo $backup | jq -r .slug)
            echo "Deleting ${theslug} ..."
            ha snapshots remove "$theslug"
            echo "Deleting ${theslug} ... done"
        fi
        i=$(($i + 1))
    done
}

function cleanup-snapshots-remote {
    input="$($SMB -c "cd ${TARGET_DIR}; ls")"
    snaps="$(echo "$input" | grep .tar | while read slug _ _ _ a b c d; do
        theDate=$(echo "$a $b $c $d" | xargs -i date +'%Y-%m-%d %H:%M' -d "{}")
        echo "$theDate $slug"
    done | sort -r)"
    echo "$snaps"

    i="1"
    echo "$snaps" | while read _ _ slug; do
        if [ -z "$KEEP_REMOTE" ] || [ "$i" -gt "$KEEP_REMOTE" ]; then
            echo "Deleting ${slug} ..."
            $SMB -c "cd ${TARGET_DIR}; rm ${slug}"
            echo "Deleting ${slug} ... done"
        fi
        i=$(($i + 1))
    done
}
###############


#### main program ####

create-snapshot
copy-snapshot
[ "$KEEP_LOCAL" != "all" ] && cleanup-snapshots-local
[ "$KEEP_REMOTE" != "all" ] && cleanup-snapshots-remote

echo "Backup finished"
exit 0
