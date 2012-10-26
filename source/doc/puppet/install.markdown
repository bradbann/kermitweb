---
layout: page
title: "Puppet master"
comments: true
sharing: true
footer: true
sidebar: false 
---


## Install the packages

With the kermit yum repository ((see: [Using the kermit repository](/doc/using_the_repo.html)) set :

{% codeblock  %}
yum -y install puppet-server 

#Installing:
# puppet-server
#Installing for dependencies:
# facter
# puppet
{% endcodeblock %}

<div class="note" markdown='1'>
With some RHEL 5 updates and the EPEL repository set, we've experienced a 
missing dependency error.

If you see this then just temporarily disable the EPEL repository, and try to 
install the packages with the base os and kermit repository only.
</div>


## Configuration of the master

The official documentation is fine.

[http://docs.puppetlabs.com/guides/setting\_up.html](http://docs.puppetlabs.com/guides/setting_up.html)


## Configuration example

See : [https://github.com/kermitfr/puppetclasses](https://github.com/kermitfr/puppetclasses)

This configuration example deploys the Kermit repository, MCollective and the
Kermit settings and keys. 


<div class="note" markdown='1'>
You'll need to provide your own .pem certs and keys.
</div>

## Troubleshooting

If you have trouble with the configuration,

* double check that your systems are time-synchronized
* double check that you have direct and reverse name resolution for your hosts

And read :

* [http://bitcube.co.uk/content/puppet-errors-explained](http://bitcube.co.uk/content/puppet-errors-explained)
* [http://docs.puppetlabs.com/guides/troubleshooting.html](http://docs.puppetlabs.com/guides/troubleshooting.html)

Try also :

{% codeblock lang:sh %}
puppet agent --test --debug --verbose --server yourmaster
openssl s_client -connect yourmaster:8140
telnet yourmaster 8140
{% endcodeblock %}


## Scalability

Webrick is for testing with a few nodes only.

Running the Puppet Master with Apache and Passenger is much more scalable.

Script for el 6.2 (`install-pupmasterpax.sh`) :

{% codeblock lang:sh %}
# Needs RHEL 6 u2
facter operatingsystemrelease | grep -q '6.2' || exit 1

PKGPATH=rpms
PPATH=$PKGPATH/passenger-el6.2
CONF=conf

yum -y install ruby rubygems make
yum -y install httpd mod_ssl

rpm -Uvh $PKGPATH/puppet/facter-1.6.7-1.el6.noarch.rpm

sed -i '/^exit 1$/d' /etc/init.d/puppetmaster
rpm -e puppet puppet-server
rm -rf /etc/puppet/ssl
rm -rf /var/lib/puppet

rpm -ivh $PKGPATH/puppet/puppet-2.7.11-2.el6.noarch.rpm \
         $PKGPATH/puppet/puppet-server-2.7.11-2.el6.noarch.rpm

         /sbin/service httpd stop
         /sbin/service puppetmaster start
         /sbin/service puppetmaster stop


# Passenger prereqs
rpm -ivh $PKGPATH/osoptional/rubygem-rake-0.8.7-2.1.el6.noarch.rpm
rpm -ivh $PPATH/rubygem-daemon_controller-0.2.5-1.noarch.rpm
yum -y install rubygem-rack rubygem-fastthread libev # repo EPEL

# Passenger from http://passenger.stealthymonkeys.com/rhel/6/
rpm -ivh $PPATH/rubygem-passenger-3.0.11-9.el6.x86_64.rpm
rpm -ivh $PPATH/rubygem-passenger-native-3.0.11-9.el6.x86_64.rpm
rpm -ivh $PPATH/rubygem-passenger-native-libs-3.0.11-9.el6_1.8.7.352.x86_64.rpm
rpm -ivh $PPATH/mod_passenger-3.0.11-9.el6.x86_64.rpm

mkdir -p /etc/puppet/rack/puppetmaster/{public,tmp}
chown puppet:puppet /usr/share/puppet/ext/rack/files/config.ru
cp -f /usr/share/puppet/ext/rack/files/config.ru /etc/puppet/rack/puppetmaster/
chown puppet:puppet /etc/puppet/rack/puppetmaster/config.ru

cp -f $CONF/puppetmaster.conf /etc/httpd/conf.d/puppetmaster.conf
sed -i "s/CHANGEME1/$(hostname)/g" /etc/httpd/conf.d/puppetmaster.conf
sed -i "s/CHANGEME2/$(hostname)/g" /etc/httpd/conf.d/puppetmaster.conf

/sbin/chkconfig httpd on
/sbin/chkconfig puppetmaster off

usermod -a -G puppet apache

/sbin/service puppetmaster stop 
/sbin/service httpd restart

sed -i '/^exit 1$/d' /etc/init.d/puppetmaster
sed -i '1i\
exit 1' /etc/init.d/puppetmaster
{% endcodeblock %}


`puppetmaster.conf` in Apache configuration :

{% codeblock lang:apacheconf %}
# /etc/httpd/conf.d/puppetmaster.conf
# It replaces webrick and listens by default on 8140

Listen 8140

<VirtualHost *:8140>

SSLEngine on
SSLProtocol -ALL +SSLv3 +TLSv1
SSLCipherSuite ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP

# Change this :
SSLCertificateFile /var/lib/puppet/ssl/certs/CHANGEME1.pem
SSLCertificateKeyFile /var/lib/puppet/ssl/private_keys/CHANGEME2.pem

SSLCertificateChainFile /var/lib/puppet/ssl/certs/ca.pem
SSLCACertificateFile /var/lib/puppet/ssl/ca/ca_crt.pem

SSLCARevocationFile /var/lib/puppet/ssl/ca/ca_crl.pem

SSLVerifyClient optional
SSLVerifyDepth 1
SSLOptions +StdEnvVars

RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e

RackAutoDetect On

DocumentRoot /etc/puppet/rack/puppetmaster/public/

<Directory /etc/puppet/rack/puppetmaster/>
Options None
AllowOverride None
Order allow,deny
allow from all
</Directory>

</VirtualHost>
{% endcodeblock %}


Cf :

* [http://docs.puppetlabs.com/guides/passenger.html](http://docs.puppetlabs.com/guides/passenger.html)
* The book 'Pro Puppet', chapter 'Puppet scalability', section 'Running the Puppet Master with Apache and Passenger'

<div class="note" markdown='1'>
if you change the default ssldir, to need to set it in the `[main]` section of puppet.conf of the puppet master.
</div>
