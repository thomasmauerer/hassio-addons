#!/usr/bin/env bashio

#### config ####

HOST=$(bashio::config 'host')
SHARE=$(bashio::config 'share')
TARGET_DIR=$(bashio::config 'target_dir')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')

echo "Host: ${HOST}"
echo "Share: ${SHARE}"
echo "Target Dir: ${TARGET_DIR}"
if [ -z "$USERNAME" ]; then
    echo "Username: guest mode"
else
    echo "Username: ${USERNAME}"
fi
###############


#### functions ####

function create-snapshot {
    name="Backup $(date +'%Y-%m-%d %H:%M')"
    echo "Creating snapshot \"${name}\" ..."
    SLUG=$(ha snapshots new --name "$name" | cut -d' ' -f2)
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

function cleanup-snapshots {
    echo "cleanup not implemented yet"
}
###############


#### main program ####

create-snapshot
copy-snapshot
#cleanup-snapshots

echo "Backup finished"
exit 0
