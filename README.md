### BSD-Scripts

# ifconf_up_down:
Please add these lines to the Crontab:
 ```
 1    12    *    *   3   /bin/sh /root/amir_if.sh down
 1    08    *    *   6   /bin/sh /root/amir_if.sh up
 ```


# rsync server - sample config:


ee /usr/local/etc/rsync/rsyncd.conf
```
uid = root
log file = /var/log/rsync.log
port = 12000  ## Default port is 873
address = 10.10.10.1

[ipdr]
    path = /data/incoming/
    comment = RSYNC IPDR
    read only = false
    timeout = 300
 ```
sysrc rsyncd_enable="YES"

Restarting Service:

/usr/local/etc/rc.d/rsyncd restart
