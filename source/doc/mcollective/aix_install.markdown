---
layout: page
title: "AIX node"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Installation of the packages

Get the packages for AIX 6.1 here :
[http://www.kermit.fr/repo/rpm/aix/RPMS/](http://www.kermit.fr/repo/rpm/aix/RPMS/)

Install :

{% codeblock lang:sh %}
rpm -Uvh openssl-0.9.8r-1.aix5.1.ppc.rpm

rpm -ivh ruby-1.9.1-1.NV_.aix6_.1.ppc.rpm # (from http://blogs.nullvision.com/)

rpm -ivh rubygem-stomp-1.1-1.aix6.1.noarch.rpm

rpm -ivh facter-1.6.0-1.aix6.1.noarch.rpm

rpm -ivh mcollective-common-1.2.1-2.aix6.1.noarch.rpm

rpm -ivh mcollective-1.2.1-2.aix6.1.noarch.rpm

rpm -ivh mcollective-plugins-agentinfo-1.0-3.aix6.1.noarch.rpm

rpm -ivh mcollective-plugins-facter_facts-1.0-1.aix6.1.noarch.rpm

rpm -ivh mcollective-plugins-nodeinfo-1.0-3.aix6.1.noarch.rpm
{% endcodeblock %}

If you want to use the backend scheduler, install in addition :

{% codeblock lang:sh %}
rpm -ivh rubygem-tzinfo-0.3.31-1.aix6.1.noarch.rpm

rpm -ivh rubygem-uuidtools-2.1.2-1.aix6.1.noarch.rpm

rpm -ivh rubygem-daemons-1.1.5-1.aix6.1.noarch.rpm

rpm -ivh rubygem-inifile-0.4.1-1.aix6.1.noarch.rpm

rpm -ivh rubygem-rufus-scheduler-2.0.16-1.aix6.1.noarch.rpm
{% endcodeblock %}

## Configuration

Test `ruby` + `openssl` :

{% codeblock lang:sh %}
ruby -ropenssl -e "puts :success"
{% endcodeblock %}

Edit `/etc/mcollective/server.cfg` (same config as for Linux)

Create a directory :

{% codeblock lang:sh %}
mkdir -p /var/lib/puppet
{% endcodeblock %}


Edit `/var/lib/puppet/classes.txt`

Put the puppet classes used for the node classification, one by line.


Enable and start MCollective :

{% codeblock lang:sh %}
ln -s /etc/rc.d/init.d/mcollectived /etc/rc.d/rc2.d/S99mcollectived
/etc/rc.d/init.d/mcollectived start
{% endcodeblock %}


