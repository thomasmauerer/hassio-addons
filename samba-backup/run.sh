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
    echo "Creating snapshot \"${name}\" ..."
    SLUG="$(ha snapshots new --name "$name" --password "$BACKUP_PWD" --raw-json | jq -r .data.slug).tar"
    echo "Creating snapshot \"${name}\" ... done"
}

function copy-snapshot {
    cd /backup
    echo "Copying snapshot ${SLUG} ..."
    $SMB -c "cd ${TARGET_DIR}; put ${SLUG}"
    echo "Copying snapshot ${SLUG} ... done"
}

function cleanup-snapshots-local {
    snaps=$(ha snapshots --raw-json | jq -c .data.snapshots[] | grep "Automatic Backup" | jq -c '{date,slug}' | sort -r)
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
