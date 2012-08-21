---
layout: page
title: "REST server"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Prerequisites

You need to install the MCollective broker first and a few MCollective nodes

## Get the packages 

See [Using the kermit repository](/doc/using_the_repo.html)

<div class="important" markdown='1'>
For RHEL 6 you also need some packages from EPEL
</div>

{% codeblock lang:sh %}
rpm -Uvh http://mirrors.ircam.fr/pub/fedora/epel/6/i386/epel-release-6-7.noarch.rpm
{% endcodeblock %}



## Install the packages

{% codeblock lang:sh %}
yum -y install kermit-restmco 

#Installing:
# kermit-restmco
#Installing for dependencies:
# rubygem-daemons
# rubygem-rack
# rubygem-sinatra
# mcollective-common
{% endcodeblock %}


## Security

The REST server is used to call MCollective and manage all your nodes. 

Therefore you must restrict the access to the REST server, with

* IP filtering (i.e. `iptables`)
* antispoofing
* system login ACL (i.e. SSH ACL) 

The web service should be reachable only from the system of the Web UI.


## Configuration (demo mode)

If you install the rest server on the same system as the Web UI, you can just
restrict the server to localhost :

{% codeblock lang:sh %}
sed -i "/^[[:space:]]*require[[:space:]]*'sinatra'/a\set :bind, 'localhost'" \
    /usr/local/bin/kermit/restmco/mc-rpc-restserver.rb
{% endcodeblock %}

The application needs a read access to `/etc/mcollective/client.cfg` :

{% codeblock lang:sh %}
chmod 644 /etc/mcollective/client.cfg
{% endcodeblock %}


Then :

{% codeblock lang:sh %}
/sbin/service kermit-restmco restart
/sbin/chkconfig kermit-restmco on
{% endcodeblock %}

Test : 

with MCollective set,

{% codeblock lang:sh %}
netstat -ntaup | grep 4567
cd /tmp
wget http://localhost:4567/ # you should get a page with 'Hello Sinatra'
wget http://localhost:4567/mcollective/no-filter/rpcutil/ping/
wget http://localhost:4567/mcollective/no-filter/package/status/package=bash
{% endcodeblock %}


## Configuration (production)

For multi user actions we will serve the (Sinatra) application though Apache and
Phusion Passenger.

### ON RHEL 5 x86\_64

The kermit yum repository (see [Using the kermit repository](/doc/using_the_repo.html)) provides passenger on RHEL 5 x86\_64 rebuilt for Ruby 1.8.6.

With the kermit repository set :

{% codeblock lang:sh %}
yum -y install mod_passenger
{% endcodeblock %}


### On RHEL 6 x86\_64

{% codeblock lang:sh %}
yum -y install http://passenger.stealthymonkeys.com/rhel/6/passenger-release.noarch.rpm
yum -y install mod_passenger
{% endcodeblock %}


### Web configuration for Apache

{% codeblock lang:sh %}
mkdir -p /var/www/restmco/{tmp,public}
touch /var/www/restmco/tmp/restart.txt
cp -f /usr/local/bin/kermit/restmco/mc-rpc-restserver.rb /var/www/restmco/

cat<<EOF>/var/www/restmco/config.ru
require 'mc-rpc-restserver'
root_dir = File.dirname(__FILE__)
set :environment, ENV['RACK_ENV'].to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'mc-rpc-restserver.rb')
#set :bind, 'localhost'
disable :run
run Sinatra::Application
EOF

cat<<EOF>/etc/httpd/conf.d/restmco.conf
<VirtualHost *:80>
   ServerName localhost 
   DocumentRoot /var/www/restmco/public
   <Directory /var/www/restmco/public>
      AllowOverride all              
      Options -MultiViews           
   </Directory>
</VirtualHost>
EOF
{% endcodeblock %}

If needed (i.e. with the REST server and the Web UI on separate systems),

* modify ServerName
* set some Apache ACL (order, deny and allow directives)

The application needs a read access to `/etc/mcollective/client.cfg` :

{% codeblock lang:sh %}
chmod 644 /etc/mcollective/client.cfg
{% endcodeblock %}

Then

{% codeblock lang:sh %}
/sbin/service kermit-restmco stop
/sbin/chkconfig kermit-restmco off
/sbin/service httpd restart
/sbin/chkconfig httpd on 
{% endcodeblock %}

### SELinux

If needed (Enforcing mode), configure SELinux :

{% codeblock lang:sh %}
yum -y install policycoreutils-python

rm -f /var/log/audit/audit.log
/sbin/service auditd restart

setenforce permissive
/sbin/service httpd restart
wget http://localhost/mcollective/no-filter/rpcutil/ping/ -O /tmp/ping.html

setenforce enforcing 

semanage port -a -t http_port_t -p tcp 6163

grep httpd /var/log/audit/audit.log | audit2allow -M passenger
semodule -i passenger.pp

semanage fcontext -a -t httpd_sys_content_t "/var/www/restmco(/.*)?"
restorecon -R /var/www/
ls -ldZ /var/www/restmco/*

/sbin/service httpd restart

{% endcodeblock %}

### Test

With MCollective set,

{% codeblock lang:sh %}
cd /tmp
wget http://localhost # you should get a page with 'Hello Sinatra'
wget http://localhost/mcollective/no-filter/rpcutil/ping/
wget http://localhost/mcollective/no-filter/package/status/package=bash
{% endcodeblock %}


Note that if you use the mcollective ssl plugin, the service needs an access to the keys used by MCollective, defined in

{% codeblock lang:sh %}
/etc/mcollective/client.cfg   # (plugin.ssl_client_private)
/etc/mcollective/server.cfg   # (plugin.ssl_server_public)
{% endcodeblock %}


## Troubleshooting

{% codeblock lang:sh %}
less /var/log/httpd/error_log
{% endcodeblock %}

You can test the service with the standalone script :

{% codeblock lang:sh %}
ruby /usr/local/bin/kermit/restmco/mc-rpc-restserver.rb
{% endcodeblock %}

Stop the service `kermit-restmco` before using that.

If you have problems when using passenger to run the application, try with
passenger standalone to get debugging hints at the console.

{% codeblock lang:sh %}
yum -y install passenger-standalone
cd /var/www/restmco/
passenger start
{% endcodeblock %}



