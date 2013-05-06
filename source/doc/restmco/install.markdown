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
rpm -Uvh http://mirrors.ircam.fr/pub/fedora/epel/6/i386/epel-release-6-8.noarch.rpm
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

curl http://localhost:4567/ # you should get a page with 'Hello Sinatra'

curl -X POST -d '' http://localhost:4567/mcollective/rpcutil/ping/

curl -X POST -H 'content-type: application/json' \
     -d '{"parameters":{"package":"bash"}}' \
     http://localhost:4567/mcollective/package/status/; echo

curl -X POST -H 'content-type: application/json' \
     -d '{"filters":{"fact":["rubyversion=1.8.7"]}}' \
     http://localhost:4567/mcollective/rpcutil/ping/; echo
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
cp /usr/local/bin/kermit/restmco/misc/restmco.conf /etc/httpd/conf.d/
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
/usr/local/bin/kermit/restmco/misc/applyse.sh

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

Try a few POST queries, see below.

### Test

With MCollective set,

{% codeblock lang:sh %}
cd /tmp

curl http://localhost/ # you should get a page with 'Hello Sinatra'

curl -X POST -d '' http://localhost/mcollective/rpcutil/ping/

curl -X POST -H 'content-type: application/json' \
     -d '{"parameters":{"package":"bash"}}' \
     http://localhost/mcollective/package/status/; echo

curl -X POST -H 'content-type: application/json' \
     -d '{"filters":{"fact":["rubyversion=1.8.7"]}}' \
     http://localhost/mcollective/rpcutil/ping/; echo
{% endcodeblock %}


Note that if you use the mcollective ssl plugin, the service needs an access to the keys used by MCollective, defined in

{% codeblock lang:sh %}
/etc/mcollective/client.cfg   # (plugin.ssl_client_private)
/etc/mcollective/server.cfg   # (plugin.ssl_server_public)
{% endcodeblock %}

If SELinux is in mode enforcing, do a `restorecon` on the key files.

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


## Install with puppet

Check :

[https://github.com/lofic/puppet-lofic/blob/master/modules/kermitrest/manifests/init.pp](https://github.com/lofic/puppet-lofic/blob/master/modules/kermitrest/manifests/init.pp)

