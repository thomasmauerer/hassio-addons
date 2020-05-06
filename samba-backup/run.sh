#!/usr/bin/env bashio

#### config ####

HOST=$(bashio::config 'host')
SHARE=$(bashio::config 'share')
TARGET_DIR=$(bashio::config 'target_dir')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
KEEP_LOCAL=$(bashio::config 'keep_local')

echo "Host: ${HOST}"
echo "Share: ${SHARE}"
echo "Target Dir: ${TARGET_DIR}"
if [ -z "$USERNAME" ]; then
    echo "Username: guest mode"
else
    echo "Username: ${USERNAME}"
fi
echo "Keep local: ${KEEP_LOCAL}"
###############


#### functions ####

function create-snapshot {
    name="Automatic Backup $(date +'%Y-%m-%d %H:%M')"
    echo "Creating snapshot \"${name}\" ..."
    SLUG=$(ha snapshots new --name "$name" --raw-json | jq -r .data.slug)
    echo "Creating snapshot \"${name}\" ... done"
}

function copy-snapshot {
    cd /backup

    echo "Copying snapshot ${SLUG}.tar ..."
    if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
        smbclient -U "$USERNAME"%"$PASSWORD" //"$HOST"/"$SHARE" -c 'cd '"$TARGET_DIR"'; put '"$SLUG".tar
    else
        smbclient -N //"$HOST"/"$SHARE" -c 'cd '"$TARGET_DIR"'; put '"$SLUG".tar
    fi
    echo "Copying snapshot ${SLUG}.tar ... done"
}

function cleanup-snapshots-local {
    echo "not implemented yet"
}
###############


#### main program ####

create-snapshot
copy-snapshot
#cleanup-snapshots-local

echo "Backup finished"
exit 0
