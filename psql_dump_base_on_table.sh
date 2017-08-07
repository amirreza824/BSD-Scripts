#!/bin/sh

DIR="/usr/home/amir/"  ## Directory that you want store dumped file

psql_user=`cat /etc/passwd | grep -i PostgreSQL | cut -f1 -d ":"`
psql_db="ipdr"
psql_app=`which psql`
psql_dump=`which pg_dump`
sudo_app=`which sudo`

table_1="route"
table_2="udr"
table_3="xdr"

cd ${DIR} ## Change Directory to Destination fo Backupng

## Table 1
${sudo_app} -i -u ${psql_user} ${psql_app} ${psql_db} -c "\dt" | grep -i "${table_1}" | cut -f 2 -d "|" |  while read line
  do
    ${sudo_app} -i -u ${psql_user} ${psql_dump} --no-owner --no-tablespaces --encoding=utf8 --username=${psql_user} -t ${line} ipdr > ${DIR}pg_dump_${line}.sql
  done

## Table 2
${sudo_app} -i -u ${psql_user} ${psql_app} ${psql_db} -c "\dt" | grep -i "${table_2}" | cut -f 2 -d "|" |  while read line
  do
    ${sudo_app} -i -u ${psql_user} ${psql_dump} --no-owner --no-tablespaces --encoding=utf8 --username=${psql_user} -t ${line} ipdr > ${DIR}pg_dump_${line}.sql
  done

## Table 3
${sudo_app} -i -u ${psql_user} ${psql_app} ${psql_db} -c "\dt" | grep -i "${table_3}" | cut -f 2 -d "|" |  while read line
  do
    ${sudo_app} -i -u ${psql_user} ${psql_dump} --no-owner --no-tablespaces --encoding=utf8 --username=${psql_user} -t ${line} ipdr > ${DIR}pg_dump_${line}.sql
  done

###################################
