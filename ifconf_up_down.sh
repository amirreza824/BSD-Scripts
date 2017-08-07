#!/bin/sh

/sbin/ifconfig | /usr/bin/egrep -i '(^$|em|pcn)' | /usr/bin/egrep -v '(^$|lo0|pf|em0)' | /usr/bin/cut -d ':' -f1 | while read line 
	do 
		/sbin/ifconfig ${line} ${1} 
	done


#########################
## Added these Line to cron:
# 1    12    *    *   3   /bin/sh /root/amir_if.sh down
# 1    08    *    *   6   /bin/sh /root/amir_if.sh up