#!/bin/sh

DIR="/usr/home/amir/"         ## Directory that you store dumped file
STAT=`which fstat`

APP=`which rsync`

## Rsync Options that you need:
# --partial -> keep partially transferred files
# --append-verify --> use checksum verification for files
# -q -> quiet
# -a --> archive mode enable
APP_OPT="-q --partial --append-verify -acvP"

DST_IP="10.10.10.1"
DST_PORT="873"          ## Default Port is 873
DST_DIR="ipdr"          ## Directive Option that defined to rsync server
LOG_file="/var/log/rsync-amir.log"          ## PLease input absolute address file for Logging

for i in ${DIR}*
do
    if ! `${STAT} ${i} | grep -q " w "`; then
        ${APP} ${APP_OPT} ${i} --log-file=${LOG_file} ${APP}://${DST_IP}:${DST_PORT}/${DST_DIR}
    fi
done
