---
layout: page
title: "Puppet client on AIX"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Install the packages

We use the packages built and provided here :

[http://t3chnick.blogspot.com/2012/01/32-bit-puppet-rpms-srpms-for-aix-howto.html](http://t3chnick.blogspot.com/2012/01/32-bit-puppet-rpms-srpms-for-aix-howto.html)

Thanks a lot to this guy !

As an alternative you can get the packages for AIX 6.1 here :

[http://www.kermit.fr/repo/rpm/aix/RPMS/](http://www.kermit.fr/repo/rpm/aix/RPMS/)

Install :

{% codeblock lang:sh %}
# Remove possibly installed db-4.4
rpm -e db
# Install db-3.3 (a needed dependency)
rpm -ivh db-3.3.11-4.aix5.1.ppc.rpm

# Installs some specific and isolated ruby, openssl, facter and puppet
# in /opt/puppet
rpm -ivh pup-zlib-1.2.5-1.32.puppet.local.aix6.1.ppc.rpm
rpm -ivh pup-openssl-1.0.0e-2.32.puppet.local.aix6.1.ppc.rpm
rpm -ivh pup-ruby-1.8.7-p352.1.32.puppet.local.aix6.1.ppc.rpm
rpm -ivh pup-facter-1.6.3-1.puppet.local.aix6.1.noarch.rpm
rpm -ivh pup-puppet-2.7.6-1.local.aix6.1.ppc.rpm
{% endcodeblock %}

## Post configuration

{% codeblock lang:sh %}
mkdir -p /var/run/puppet
mkdir -p /var/lib/puppet/ssl
mkdir -p /usr/libexec/mcollective/mcollective/agent/

PUPPETMASTER=puppetmaster.fqdn # <- change this to fit your environment

cat<< EOF> /etc/puppet/puppet.conf
[main]
   logdir = /var/log/puppet
   rundir = /var/run/puppet
   ssldir = /var/lib/puppet/ssl
   server = $PUPPETMASTER 
   pluginsync = true
[agent]
   classfile = /var/lib/puppet/classes.txt
   localconfig = /var/lib/puppet/localconfig
EOF
{% endcodeblock %}

## First run

{% codeblock lang:sh %}
# Configure everything else with the puppet master
/opt/puppet/pup-puppet/bin/puppet agent --test
/opt/puppet/pup-puppet/bin/puppet agent --test # Double check
{% endcodeblock %}


## Notes

### Init service script

Not provided with the packages.

Get one here :

[http://www.kermit.fr/stuff/misc/puppet.initscript.aix](http://www.kermit.fr/stuff/misc/puppet.initscript.aix)

Enable and start with :

{% codeblock lang:sh %}
cp puppet.initscript.aix /etc/rc.d/init.d/puppet

chmod +x /etc/rc.d/init.d/puppet
ln -s /etc/rc.d/init.d/puppet /etc/rc.d/rc2.d/S99puppet
/etc/rc.d/init.d/puppet start
{% endcodeblock %}

You can deploy the script with puppet itself. 

### Alias

The binaries are not in the standard `PATH`

You can use an alias for convenience.

{% codeblock lang:sh %}
alias pat='/opt/puppet/pup-puppet/bin/puppet agent --test'
{% endcodeblock %}


You can deploy the alias with puppet itself. 

