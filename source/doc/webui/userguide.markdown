---
layout: page
title: "WebUI admin and user guide"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Administration

### Hide some widgets on the Dashboard
For example, hide the Agents tree or the Default Operations widget.

Admin area -> Widgets -> Clic on the widget name

Uncheck 'Enabled'

Push the 'Save' button.

### Change the logo of the web UI

{% codeblock lang:sh %}
cp new_logo.png /var/www/kermit-webui/static/images/header/

sed -i 's/kermit_logo.png/new_logo.png/g' /usr/share/kermit-webui/templates/theme/kermit/header.html
{% endcodeblock %}

### Status of the services

The status is available at the bottom line of the web dashboard.

* REST  : communication between the web interface and the mcollective orchestrator (`kermit-restmco`)
* TaskMan    : task manager (`celery`)
* TaskMon    : task monitor (`celeryev`)
* TaskBroker : message broker for the task manager (`redis`)
* SchedMan   : task scheduler (`celerybeat`)
* InvQueue   : queue for receiving the inventories of the managed systems (`kermit-inventory`)
* LogQueue   : queue for receiving the logs of the managed systems (`kermit-log`)

### Restart the services

In the right order :

{% codeblock lang:sh %}
/sbin/service kermit-restmco stop
/sbin/service httpd stop
/sbin/service celeryev stop
/sbin/service celerybeat stop
/sbin/service celeryd stop

sleep 5

/sbin/service redis restart 
/sbin/service celeryd start
/sbin/service celerybeat start
sleep 5
/sbin/service celeryev start
/sbin/service httpd start
/sbin/service kermit-restmco start

/sbin/service kermit-inventory restart
/sbin/service kermit-log restart
{% endcodeblock %}


### Purge the old failed and waiting jobs

{% codeblock lang:sh %}
# PostgreSQL :
su - postgres -c 'psql kermit -c "delete from restserver_backendjob;"'

# SQLite :
sqlite3 -line /var/lib/kermit/webui/db/sqlite.db 'delete from restserver_backendjob;'
{% endcodeblock %}


### Purge redis

You should also consider tuning `maxmemory` in `redis.conf`

{% codeblock lang:sh %}
/sbin/service celeryd stop
/sbin/service celerybeat stop
/sbin/service celeryev stop

echo 'flushall' | /usr/bin/redis-cli
/sbin/service redis restart
ps aux | egrep 'redis|PID' | grep -v grep
sleep 5

/sbin/service celeryd start
sleep 5
/sbin/service celerybeat start
/sbin/service celeryev start
{% endcodeblock %}


### To do

* manage users and groups
* set ACL on users, groups, nodes and agents

We should also provide some screencasts.


## User guide

To do.
