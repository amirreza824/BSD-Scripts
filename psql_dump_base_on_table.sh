#!/bin/sh

sudo -i -u pgsql psql ipdr -c "\dt" | grep -i "route" | cut -f 2 -d "|" |  while read line ; do sudo -i -u pgsql pg_dump --no-owner --no-tablespaces --encoding=utf8 --username=pgsql 
-t ${line} ipdr > /usr/home/amir/pg_dump_${line}.sql ; done
sudo -i -u pgsql psql ipdr -c "\dt" | grep -i "udr" | cut -f 2 -d "|" |  while read line ; do sudo -i -u pgsql pg_dump --no-owner --no-tablespaces --encoding=utf8 --username=pgsql -t 
${line} ipdr > /usr/home/amir/pg_dump_${line}.sql ; done
sudo -i -u pgsql psql ipdr -c "\dt" | grep -i "xdr" | cut -f 2 -d "|" |  while read line ; do sudo -i -u pgsql pg_dump --no-owner --no-tablespaces --encoding=utf8 --username=pgsql -t 
${line} ipdr > /usr/home/amir/pg_dump_${line}.sql ; done

