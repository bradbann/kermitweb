---
layout: page
title: "Linux RHEL node"
comments: true
sharing: true
footer: true
sidebar: false 
---

This can be a RHEL or Centos 4, 5 or 6.

## Prerequisites

There must be a valid direct and reverse DNS entry for each node (management
and managed hosts).


## Get the packages

See [Using the kermit repository](/doc/using_the_repo.html)

<div class="important" markdown='1'>
For RHEL 6 you also need some packages from EPEL
</div>

{% codeblock lang:sh %}
rpm -Uvh http://mirrors.ircam.fr/pub/fedora/epel/6/i386/epel-release-6-7.noarch.rpm
{% endcodeblock %}


## Install the packages

### Install some packages from the base RHEL or Centos repository

Those packages are required as dependencies.

{% codeblock lang:sh %}
yum -y install tk unixODBC
{% endcodeblock %}


### Install ruby and some gems

{% codeblock lang:sh %}
yum -y install ruby rubygems rubygem-stomp
{% endcodeblock %}


This is required for Puppet and MCollective.

el4 : custom build of Ruby 1.8.6

el5 : Ruby 1.8.6 from ELFF

el6 : standard Ruby 1.8.7 from the Linux distribution


### Install MCollective

{% codeblock lang:sh %}
yum -y install mcollective-common mcollective
{% endcodeblock %}

### Configure MCollective

Edit `/etc/mcollective/server.cfg`

Set `plugin.stomp.host` = the hostname of your message broker.

Set `plugin.stomp.port` = 6163

Set `plugin.stomp.user` and `plugin.stomp.password` with the values you set in the message broker configuration.

Example :

{% codeblock lang:cfg %}
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
logfile = /var/log/mcollective.log
loglevel = info
daemonize = 1

# Plugins
securityprovider = psk
plugin.psk = unset

connector = stomp
plugin.stomp.host = your_broker_fqdn
plugin.stomp.port = 6163
plugin.stomp.user = mcollective
plugin.stomp.password = marionette

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
{% endcodeblock %}



### Enable and start all the services

{% codeblock lang:sh %}
/sbin/chkconfig mcollective on
/etc/init.d/mcollective restart
{% endcodeblock %}


### Test the configuration

You'll need a MCollective client node.

See [Configuration of a client (a management node)](/doc/mcollective/client.html) 

From a MCollective node with a client configuration :

{% codeblock lang:sh %}
mco ping
mc-find-hosts
mco facts mcollective
{% endcodeblock %}


### Install additional packages

For more agents. Deploy on all nodes.

Facter : 

{% codeblock lang:sh %}
yum -y install facter
{% endcodeblock %}


Install Puppet (from people.fedoraproject.org) and some required packages 
(from EPEL) :

{% codeblock lang:sh %}
yum -y install augeas-libs ruby-augeas ruby-shadow puppet
{% endcodeblock %}


Install some mcollective plugins (custom packages):

{% codeblock lang:sh %}
yum -y install mcollective-plugins-facter_facts mcollective-plugins-package \
 mcollective-plugins-service

yum -y install mcollective-plugins-agentinfo.noarch \
 mcollective-plugins-nodeinfo.noarch
{% endcodeblock %}

Then :

{% codeblock lang:sh %}
touch /var/lib/puppet/classes.txt
{% endcodeblock %}


Now you can replace in `/etc/mcollective/server.cfg` and `client.cfg` (if
present) :

{% codeblock lang:cfg %}
factsource = yaml
{% endcodeblock %}


with :

{% codeblock lang:cfg %}
factsource = facter 
{% endcodeblock %}


Test the additional agents from a mcollective client with :

{% codeblock lang:sh %}
mc-controller reload_agents
mco rpc rpcutil agent_inventory
mco rpc service status service=sshd
mco rpc package status package=bash
mc-rpc package status package=bash
mc-package status bash
mco rpc nodeinfo basicinfo
{% endcodeblock %}


## Summary of installed packages

{% codeblock lang:sh %}
yum -y install tk unixODBC
yum -y install ruby rubygems rubygem-stomp
yum -y install mcollective-common mcollective
yum -y install facter
yum -y install augeas-libs ruby-augeas ruby-shadow puppet
yum -y install mcollective-plugins-facter_facts mcollective-plugins-package \
 mcollective-plugins-service
yum -y install mcollective-plugins-agentinfo.noarch \
 mcollective-plugins-nodeinfo.noarch
{% endcodeblock %}


## Automatic deployment

See [Automatic Deployment](/doc/mcollective/autodeploy.html). 



