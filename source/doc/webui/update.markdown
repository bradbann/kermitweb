---
layout: page
title: "Update the WebUI"
comments: true
sharing: true
footer: true
sidebar: false 
---


## Update 

{% codeblock lang:sh %}
#!/bin/bash
test $EUID -eq 0 || { echo "This script must be run as root"; exit 1; }

rpm=kermit-webui-x.y.z-t.noarch.rpm

/sbin/service httpd stop
/sbin/service celeryev stop
/sbin/service celerybeat stop
/sbin/service celeryd stop

sleep 5

rpm -Uvh $rpm

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
