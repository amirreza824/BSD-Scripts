#!/bin/sh

PFAPP="/sbin/pfctl"
SRCFILE="/tmp/srclist.txt"
SUBNET="100"

####################################################
################## Functions: ######################

PRV_to_PUB () {
  RESULT=`cat $SRCFILE | grep -i ${INIP} | cut -d " " -f 3`
  echo $RESULT | xargs -n1
}

PUB_to_PRV () {
  RESULT=`cat $SRCFILE | grep -i ${INIP} | cut -d " " -f 1`
  echo $RESULT | xargs -n1
}

####################################################
############ Checking Sourc IP File:################

if [ -f ${SRCFILE} ]
  then
    CTIME=`stat -f "%c" ${TMPFILE}`
    NTIME=`date +"%s"`
    DIFF=`expr ${NTIME} - ${CTIME}`
    if [ ${DIFF} -gt 300 ]
      then
        ${PFAPP} -sS > ${SRCFILE}
      fi
else
    ${PFCTL} -sS > ${TMPFILE}
fi

####################################################
############ Checking type of Input IP:#############

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Please RUN: sh ${0} IP"
    exit 1
else
  INIP="$1"
fi

if [ `echo ${INIP} | awk -F '.' '{print $1}'` == ${SUBNET} ]
    then
        PRV_to_PUB ${INIP}
        exit 0
    else
        PUB_to_PRV ${INIP}
        exit 0
fi

####################################################
####################################################
