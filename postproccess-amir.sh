#!/bin/sh


set -u
#set -x


DATE='/bin/date'
SUDO='/usr/local/bin/sudo'
PSQL_USER="postgres"
PSQL_DB="ipdr"
PSQL_APP="/usr/local/bin/psql"
PG_DUMP_APP="/usr/local/bin/pg_dump"
TYPE="ipfix"
STRUCT_IPDR="id bigserial, ts integer NOT NULL, proto int NOT NULL, sip inet NOT NULL,sport int NOT NULL, nip inet NOT NULL, nport int NOT NULL, dip inet NOT NULL, dport int NOT NULL"

################################################################################
################################## PART 1 ######################################
################ Work Day Separation and Find specific HOST ####################

# InPut Date Syntax = YYYYMMDD , exp: 20170101
if [ $# -lt 1 ]
  then
    WDATE=$(${DATE} -v-1d "+%Y%m%d")    ## Work Day
    TS_START_WDATE=$(${DATE} -j -f "%Y%m%d%H%M%S" +%s ${WDATE}000000)
    TS_END_WDATE=$((${TS_START_WDATE} + 86399))
  else
    WDATE=$1    ## Work Day
    TS_START_WDATE=$(${DATE} -j -f "%Y%m%d%H%M%S" +%s ${WDATE}000000)
    TS_END_WDATE=$((${TS_START_WDATE} + 86399))
  fi

# Find HOST:
  DTS="3599"
  for i in `seq -f "%02g" 0 23`
    do
      eval WDATE_${i}_HOST=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT host FROM manifest WHERE table_name = '${TYPE}${WDATE}_${i}' ;"`
      eval WDATE_${i}_END_TS=$((${TS_START_WDATE} + ${DTS}))
      eval WDATE_${i}_START_TS=$((${TS_START_WDATE} + ${DTS} - 3599))

      DTS=$((${DTS} + 3600))

    done


################################################################################
################################## PART 2 ######################################
######## clean up specific table and move extra records to temp table ##########

for i in `seq -f "%02g" 0 23`
  do
    TMP_HOST="$(eval echo \${WDATE_${i}_HOST})"
    TMP_START_TS="$(eval echo \${WDATE_${i}_START_TS})"
    TMP_END_TS="$(eval echo \${WDATE_${i}_END_TS})"
    TMP_TABLE="TMP_WDATE_${WDATE}"

    ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${TMP_HOST} -c "SELECT * into ${TMP_TABLE} FROM ${TYPE}${WDATE}_${i} WHERE ts NOT BETWEEN ${TMP_START_TS} AND ${TMP_END_TS} ;"
    ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${TMP_HOST} -c "DELETE FROM ${TYPE}${WDATE}_${i} WHERE ts NOT BETWEEN ${TMP_START_TS} AND ${TMP_END_TS} ;"
  done



################################################################################
################################## PART 3 ######################################
########### create tmp_ipfixYYYMMDD_HH from tmp table in PART 2 ################

for y in `seq 1 5`
  do

    NEW_WDATE=$(${DATE} -v-${y}d  -j -f "%Y%m%d" ${WDATE} +"%Y%m%d")
    TS_START_NEW_WDATE=$(${DATE} -j -f "%Y%m%d%H%M%S" +%s ${NEW_WDATE}000000)
    TS_END_NEW_WDATE=$((${TS_START_NEW_WDATE} + 86399))

    HOST_COUNT_WDATE=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT COUNT(DISTINCT(host)) FROM manifest WHERE table_name ILIKE '${TYPE}${WDATE}_%' ;"`
    HOST_COUNT_NEW_WDATE=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT COUNT(DISTINCT(host)) FROM manifest WHERE table_name ILIKE '${TYPE}${NEW_WDATE}_%' ;"`

    HOSTs_WDATE=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT DISTINCT(host) FROM manifest WHERE table_name ILIKE '${TYPE}${WDATE}_%' ;"`
    HOSTs_NEW_WDATE=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT DISTINCT(host) FROM manifest WHERE table_name ILIKE '${TYPE}${NEW_WDATE}_%' ;"`

    OLD_TMP_TABLE="TMP_WDATE_${WDATE}"


    echo ${HOSTs_WDATE} | tr ' ' '\n' | while read line
      do
        ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${line} -c "CREATE INDEX IF NOT EXISTS ${OLD_TMP_TABLE}_TS_idx ON ${OLD_TMP_TABLE} USING BRIN(ts) ;"

        DTS="3599"
        for i in `seq -f "%02g" 0 23`
          do
            #eval NEW_WDATE_${i}_HOST=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT host FROM manifest WHERE table_name = '${TYPE}${NEW_WDATE}_${i}' ;"`
            eval NEW_WDATE_${i}_END_TS=$((${TS_START_NEW_WDATE} + ${DTS}))
            eval NEW_WDATE_${i}_START_TS=$((${TS_START_NEW_WDATE} + ${DTS} - 3599))

            DTS=$((${DTS} + 3600))

            NEW_TMP_TABLE="TMP_IPFIX_${NEW_WDATE}_${i}"
            TMP_START_TS="$(eval echo \${NEW_WDATE_${i}_START_TS})"
            TMP_END_TS="$(eval echo \${NEW_WDATE_${i}_END_TS})"

            ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${line} -c "CREATE TABLE IF NOT EXISTS ${NEW_TMP_TABLE} (${STRUCT_IPDR})"
            ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${line} -c "INSERT INTO ${NEW_TMP_TABLE} SELECT * FROM ${OLD_TMP_TABLE} WHERE ts BETWEEN ${TMP_START_TS} AND ${TMP_END_TS} ;"
            ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${line} -c "DELETE FROM ${OLD_TMP_TABLE} WHERE ts BETWEEN ${TMP_START_TS} AND ${TMP_END_TS} ;"

          done
        done



############################ Dispath Data Logs #################################


        echo ${HOSTs_WDATE} | tr ' ' '\n' | while read line
          do
            DTS="3599"
            for i in `seq -f "%02g" 0 23`
                do
                  eval NEW_WDATE_${i}_HOST=`${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -A -t -c "SELECT host FROM manifest WHERE table_name = '${TYPE}${NEW_WDATE}_${i}' ;"`
                  NEW_TMP_HOST="$(eval echo \${NEW_WDATE_${i}_HOST})"
                  NEW_TMP_TABLE="TMP_IPFIX_${NEW_WDATE}_${i}"
                  TMP_DST_TABLE="${TYPE}${NEW_WDATE}_${i}"

                  ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${line} -c "\copy  (SELECT * FROM ${NEW_TMP_TABLE}  ) to STDOUT " | ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${NEW_TMP_HOST} -c "\copy ${TMP_DST_TABLE} from STDOUT"
                  ${SUDO} -u ${PSQL_USER} ${PSQL_APP} -d ${PSQL_DB} -h ${line} -c "DROP TABLE ${NEW_TMP_TABLE};"
                done
          done


    done
