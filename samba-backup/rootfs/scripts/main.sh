#!/usr/bin/env bashio

declare SLUG
declare SNAP_NAME


# ------------------------------------------------------------------------------
# Create a new snapshot (full or partial).
# ------------------------------------------------------------------------------
function create-snapshot {
    local args
    local addons
    local folders

    SNAP_NAME=$(generate-snapshot-name)

    args=()
    args+=("--name" "$SNAP_NAME")
    [ -n "$BACKUP_PWD" ] && args+=("--password" "$BACKUP_PWD")

    # do we need a partial backup?
    if [[ -n "$EXCLUDE_ADDONS" || -n "$EXCLUDE_FOLDERS" ]]; then
        # include all installed addons that are not listed to be excluded
        addons=$(ha addons --raw-json | jq -rc '.data.addons[] | select (.installed == true) | .slug')
        for ad in ${addons}; do [[ ! $EXCLUDE_ADDONS =~ "$ad" ]] && args+=("-a" "$ad"); done

        # include all folders that are not listed to be excluded
        folders=(homeassistant ssl share addons/local media)
        for fol in ${folders[@]}; do [[ ! $EXCLUDE_FOLDERS =~ "$fol" ]] && args+=("-f" "$fol"); done
    fi

    # run the command
    bashio::log.info "Creating snapshot \"${SNAP_NAME}\""
    SLUG="$(ha backups new "${args[@]}" --raw-json | jq -r .data.slug)"
}

# ------------------------------------------------------------------------------
# Copy the latest snapshot to the remote share.
# ------------------------------------------------------------------------------
function copy-snapshot {
    local store_name=$(generate-filename "$SNAP_NAME")
    local input
    local count

    # append number to filename if already existing
    input="$(eval "${SMB} -c 'cd \"${TARGET_DIR}\"; ls'")"
    count=$(echo "$input" | grep "\<$store_name.*\.tar\>" | wc -l)
    (( "$count" > 0 )) && store_name="${store_name}${count}.tar" || store_name="${store_name}.tar"

    bashio::log.info "Copying snapshot ${SLUG} (${store_name}) to share"
    cd /backup

    if ! run-and-log "${SMB} -c 'cd \"${TARGET_DIR}\"; put ${SLUG}.tar ${store_name}'"; then
        bashio::log.warning "Could not copy snapshot ${SLUG} to share. Trying again ..."
        sleep 5
        run-and-log "${SMB} -c 'cd \"${TARGET_DIR}\"; put ${SLUG}.tar ${store_name}'"
    fi
}

# ------------------------------------------------------------------------------
# Delete old local snapshots.
# ------------------------------------------------------------------------------
function cleanup-snapshots-local {
    local snaps
    local slug

    [ "$KEEP_LOCAL" == "all" ] && return 0

    snaps=$(ha backups --raw-json | jq -c '.data.backups[] | {date,slug,name}' | sort -r)
    bashio::log.debug "$snaps"

    echo "$snaps" | tail -n +$(($KEEP_LOCAL + 1)) | while read backup; do
        slug=$(echo $backup | jq -r .slug)
        bashio::log.info "Deleting ${slug} local"
        run-and-log "ha backups remove ${slug}"
    done
}

# ------------------------------------------------------------------------------
# Delete old snapshots on the share.
# ------------------------------------------------------------------------------
function cleanup-snapshots-remote {
    local input
    local snaps

    [ "$KEEP_REMOTE" == "all" ] && return 0

    # read all tar files that match the snapshot name pattern and sort them
    input="$(eval "${SMB} -c 'cd \"${TARGET_DIR}\"; ls'")"
    snaps="$(echo "$input" | grep -E '\<([0-9a-f]{8}|Samba_Backup_.*)\.tar\>' | while read name _ _ _ a b c d; do
        theDate=$(echo "$a $b $c $d" | xargs -i date +'%Y-%m-%d %H:%M' -d "{}")
        echo "$theDate $name"
    done | sort -r)"
    bashio::log.debug "$snaps"

    echo "$snaps" | tail -n +$(($KEEP_REMOTE + 1)) | while read _ _ name; do
        bashio::log.info "Deleting ${name} on share"
        run-and-log "${SMB} -c 'cd \"${TARGET_DIR}\"; rm ${name}'"
    done
}
