#!/usr/bin/env bashio

HOST=$(bashio::config 'host')
SHARE=$(bashio::config 'share')

echo "Host: ${HOST}"
echo "Share: ${SHARE}"


# do the work here


echo "Backup finished"
exit 0
