---
layout: page
title: "Install the WebUI"
comments: true
sharing: true
footer: true
sidebar: false 
---

<div class="important" markdown='1'>
You need to install the REST server first.
</div>

## Requisites

You need a RHEL/Centos 5 or 6 x86\_64

The Web UI has been tested with Firefox 6+ and the latest version of
Google Chrome.

It is reported to work with IE 9. 

It is not compatible with Firefox 3.x.

Open TCP port 80 on the system where you install the WebUI

With the basic RHEL/Centos 6 firewall, in `/etc/sysconfig/iptables` add this
rules at the right place in the chain :

{% codeblock sh %}
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
{% endcodeblock %}

And restart the firewall :

{% codeblock lang:sh %}
/sbin/service iptables restart
{% endcodeblock %}


## Install the packages

The packages are provided with the kermit yum repository (see [Using the kermit repository](/doc/using_the_repo.html)).

RHEL/Centos 5 :

{% codeblock lang:sh %}
yum -y install httpd Django redis uuid \
 python26 python26-docutils ordereddict python26-httplib2 python26-redis python26-mod_wsgi \
 django-celery django-grappelli django-guardian django-kombu django-picklefield

yum -y install kermit-webui
{% endcodeblock %}

RHEL/Centos 6 :
{% codeblock lang:sh %}
# Needs EPEL in addition to the kermit repository
# Not compatible with the RepoForge repository (conflicts)
rpm -Uvh http://mirrors.ircam.fr/pub/fedora/epel/6/i386/epel-release-6-8.noarch.rpm

yum -y install httpd Django redis uuid\
 python-docutils python-ordereddict python-httplib2 python-redis \
 python-dateutil15 python-amqplib mod_wsgi\
 django-celery django-grappelli django-guardian django-kombu django-picklefield

yum -y install kermit-webui
{% endcodeblock %}

## Configure Kermit

After the installation you need to run the setup script in order to execute all
necessary configuration steps

{% codeblock lang:sh %}
/usr/share/kermit-webui/setup.sh
{% endcodeblock %}

The script will read kermit-webui.cfg file information to get access to
database. By default it will create a sqlite3 database.
If you want to change this, check the _Customization_ section.  

## Configure the binding to the REST server

The Web UI communicates with the MCollective backend via the REST server.

The out-of-the-box configuration of the Web UI package assumes that the REST
server is listening on the same host and on the default Sinatra port
(http://localhost:4567/).

If you configured the REST server on an other host or to be served by Passenger,
you need to change the default configuration in `/etc/kermit/kermit-webui.cfg`

Example for a REST server on localhost with Passenger :

{% codeblock lang:ini %}
rest_server_url=http://localhost/mcollective/
rest_server_ping_url=http://localhost/
rest_server_scheduler=http://localhost/schedule/
rest_server_scheduler_status=http://localhost/schedstatus/
rest_server_scheduler_output=http://localhost/schedoutput/
{% endcodeblock %}

 
## Configure Apache

You will need to use the fqdn of the machine (not `localhost`) to access the WebUI.

{% codeblock lang:sh %}
sed -i "s/changeme.fqdn/$(hostname)/g" /etc/httpd/conf.d/kermit-webui.conf
{% endcodeblock %}

If you have activemq running on the same system, you need to disable some proxy
features :

{% codeblock lang:sh %}
sed -i 's/^\(.*\)$/#\1/g' /etc/httpd/conf.d/activemq-httpd.conf
{% endcodeblock %}

## Enable Apache at startup and start Apache

{% codeblock lang:sh %}
/sbin/chkconfig httpd on
/sbin/service httpd restart
{% endcodeblock %}


## Celery

We use Celery ([http://celeryproject.org](http://celeryproject.org)), a distributed task manager.

This framework allows kermit to execute reliable asynchronous operations.

During the Kermit-WebUI installation, celery (and django-celery) is
installed as a dependency.

By default the kermit webUI has a couple of task scheduled to refresh server
basic info and server inventory.

We use a bunch of services to handle asynchonous task operations, scheduling,
and monitoring.

* Celery     : task manager
* Celerybeat : task scheduler
* Celeryev   : task monitor
* Redis      : task broker

Before starting kermit, you should start the celery and helper services :

{% codeblock lang:sh %}
/sbin/chkconfig redis on
/sbin/service redis start

/sbin/chkconfig celeryd on
/sbin/service celeryd start

/sbin/chkconfig celerybeat on
/sbin/service celerybeat start

/sbin/chkconfig celeryev on
/sbin/service celeryev start
{% endcodeblock %}

By default Kermit uses redis as a broker transport. 

## Go to the webUI

http://your\_noc\_server/


## Authentication

By default the package uses the inbuilt authentication.

Login : admin
Password : admin

Change this at first login.

## Post installation

{% video http://www.kermit.fr/video/kermit-post_installation_steps.mp4 1280 720 http://www.kermit.fr/video/kermit-post_installation_steps.png %}

<div class="note" markdown='1'>
Firefox users : if you can't display the video, try <a href='http://www.kermit.fr/video/kermit-post_installation_steps.mp4'>this direct link</a> with one of these firefox plugins: Gstreamer/VLC/Divx web player/Windows media player.
</div>



## SELinux

If you have SELInux in enforcing mode, you need :

{% codeblock lang:sh %}
yum -y install policycoreutils-python # el6, for el5 : policycoreutils
/usr/share/kermit-webui/selinux/applyse.sh
/sbin/service httpd restart
{% endcodeblock %}

If you still have some problems with SELinux, troubleshoot with :

{% codeblock lang:sh %}
yum -y install setroubleshoot-server
setenforce Permissive
/sbin/service auditd restart
tail /var/log/audit.log
tail /var/log/messages
sealert -a /var/log/audit/audit.log
{% endcodeblock %}

while using the WebUI.

## Customization

### Switch the database to PostgreSQL

This is recommended. SQLite should be used only for testing.

With SQLite we experienced database locks due to concurrency.

You can get rid of this problem by switching to PostgreSQL.

#### Installation of PostgreSQL

To install PostgreSQL and needed dependencies for Kermit on el5 :

RHEL/Centos 5 :

{% codeblock lang:sh %}
yum -y install postgresql84-server python26-psycopg2
{% endcodeblock %}

`postgresql84` is available on the repository 'Centos 5 - Updates'

`python26-psycopg2` is available on the Kermit repository. 

RHEL/Centos 6 :

{% codeblock lang:sh %}
yum -y install postgresql-server python-psycopg2
{% endcodeblock %}


#### Start your PostgreSQL service

{% codeblock lang:sh %}
/sbin/chkconfig postgresql on
/sbin/service postgresql start
{% endcodeblock %}


#### Configure PostgreSQL

Create a kermit user for PostgreSQL

{% codeblock lang:sh %}
su - postgres -c 'createuser kermit --no-superuser --no-createrole \
                  --no-createdb --no-password' 
su - postgres -c "psql -c \"ALTER USER kermit WITH PASSWORD '<your_pass>';\"";
{% endcodeblock %}

Create an empty database for Kermit

{% codeblock lang:sh %}
su - postgres -c \
    "psql template1 -c \"CREATE DATABASE kermit OWNER kermit ENCODING 'UTF8';\""
{% endcodeblock %}

Configure the access to your database for the Kermit server.

For example, if you have PostgreSQL installed on the Kermit machine, you just
need to allow access for a connection on localhost.

You can do this by adding two lines *BEFORE* the other rules in
`/var/lib/pgsql/data/pg_hba.conf`

{% codeblock lang:sh %}
host   kermit      kermit      127.0.0.1/32                md5
local  kermit      kermit                                  md5
{% endcodeblock %}


If you have PostgreSQL configured on a different server you can allow access
just for the Kermit machine on the Kermit database :

{% codeblock lang:sh %}
host   kermit      kermit      <kermit.ip.addr>/32         md5
{% endcodeblock %}

After these modifications you need to restart the PostgreSQL service.

{% codeblock lang:sh %}
/sbin/service postgresql restart
{% endcodeblock %}



#### Reconfigure Kermit

Configure the WebUI for using PostgreSQL, in `/etc/kermit/kermit-webui.cfg` :

{% codeblock lang:sh %}
[webui-database]
driver=postgresql_psycopg2
name=kermit
host=
port=
user=kermit
password=<your_pass>
{% endcodeblock %}


Enable the `autocommit` property in the database options.

Modify the file `/usr/share/kermit-webui/webui/settings.py` and uncomment
(remove '#' chars) these lines :

{% codeblock lang:python %}
        #'OPTIONS': {
        #    'autocommit': True,
        #}
{% endcodeblock %}


Run the kermit `setup.sh` script to recreate all tables and add some default
data.

{% codeblock lang:sh %}
/usr/share/kermit-webui/setup.sh
{% endcodeblock %}


You should now have all tables and data created in your Kermit PostgreSQL
database.

Start or restart the web and celery services.

{% codeblock lang:sh %}
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
/sbin/service httpd restart
{% endcodeblock %}


#### Optimizing PostgreSQL's configuration

This is optional.

Check the [official Django documentation -  database notes](https://docs.djangoproject.com/en/dev/ref/databases/)

### Change the web root directory (optional)

Let's say you want to switch from `http://your_noc_server/` 
to `http://your_noc_server/kermit`

Edit `/etc/httpd/conf.d/kermit-webui.conf`

Replace :

{% codeblock lang:sh %}
WSGIScriptAlias / /etc/kermit/webui/scripts/django.wsgi
{% endcodeblock %}

With :

{% codeblock lang:sh %}
WSGIScriptAlias /kermit /etc/kermit/webui/scripts/django.wsgi
{% endcodeblock %}

Edit `/etc/kermit/kermit-webui.cfg`

Replace :

{% codeblock lang:ini %}
base_url=
{% endcodeblock %}

With :

{% codeblock lang:ini %}
base_url=/kermit
{% endcodeblock %}


Then restart the web server.


### Web UI logo

Put the image in

`/var/www/kermit-webui/static/images/header/`

Set the logo in

`/usr/share/kermit-webui/templates/theme/kermit/header.html`


