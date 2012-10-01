---
layout: page
title: "Update the WebUI"
comments: true
sharing: true
footer: true
sidebar: false 
---


## Reinstall with a fresh database

<div class="warning" markdown='1'>
This will destroy all you user accounts, groups and ACLs
</div>

{% codeblock lang:sh %}
#!/bin/bash
test $EUID -eq 0 || { echo "This script must be run as root"; exit 1; }

rpm=kermit-webui-x.y.z-t.noarch.rpm

/sbin/service httpd stop
/sbin/service celeryev stop
/sbin/service celerybeat stop
/sbin/service celeryd stop

sleep 5

rpm -e kermit-webui
rpm -ivh $rpm

mv /etc/kermit/kermit-webui.cfg.rpmsave /etc/kermit/kermit-webui.cfg
mv /etc/httpd/conf.d/kermit-webui.conf.rpmsave /etc/httpd/conf.d/kermit-webui.conf

/sbin/service redis restart
/sbin/service celeryd start
/sbin/service celerybeat start
sleep 5
/sbin/service celeryev start
/sbin/service httpd restart

/sbin/chkconfig celeryd on
/sbin/chkconfig celerybeat on
/sbin/chkconfig celeryev on
/sbin/chkconfig redis on
{% endcodeblock %}


Then connect into the web UI with user = 'admin' and password = 'admin'

In the Admin Area, 

* Refresh Server Basic Info
* Update Agents Info
* Refresh Server Inventory

And reimport your ACLs


