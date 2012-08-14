---
layout: page
title: "Mcollective client"
comments: true
sharing: true
footer: true
sidebar: false 
---


## Introduction

A MCollective client can run actions of MCollective agents on the managed nodes.

Therefore a client is a management node.

Below you'll find a basic configuration and how to configure a MCollective 
client with additional security by using the MCollective SSL plugin.

Please refer to [Secure MCollective](http://www.kermit.fr/documentation/mcollective/ssl.html) for a background on MCollective security with SSL.


## Basic configuration

For test and demo systems.


### Install the mcollective-client package

On your client node(s) only.

{% codeblock lang:sh %}
yum -y install mcollective-client
{% endcodeblock %}


### Edit the settings

The parameters in `/etc/mcollective/client.cfg` must correspond to the settings
in `/etc/mcollective/server.cfg`

For example :

{% codeblock lang:cfg %}
# Plugins
securityprovider = psk
plugin.psk = unset

connector = stomp
plugin.stomp.host = your_broker_fqdn 
plugin.stomp.port = 6163
plugin.stomp.user = mcollective
plugin.stomp.password = marionette
{% endcodeblock %}

### Give it a try

On your client node, run :

{% codeblock lang:sh %}
mco ping
{% endcodeblock %}



## Advanced configuration

For production systems.

### Create a specific MQ user account

#### With ActiveMQ

In `/etc/activemq/activemq.xml` :

{% codeblock lang:xml %}
<simpleAuthenticationPlugin>
  <users>
    <!-- ... -->
    <authenticationUser username="noc" password="nocpassword"
                        groups="mcollective,admins,everyone"/>
  </users>
</simpleAuthenticationPlugin>
{% endcodeblock %}

Then restart the service ActiveMQ.


#### With RabbitMQ

{% codeblock lang:sh %}
rabbitmqctl add_user noc nocpassword
{% endcodeblock %}


And set permissions :

{% codeblock lang:sh %}
rabbitmqctl set_permissions -p / noc "^amq.gen-.*" ".*" ".*"
{% endcodeblock %}



### Create a SSL private key/public key pair

{% codeblock lang:sh %}
openssl genrsa -out noc-private.pem 1024
openssl rsa -in noc-private.pem -out noc-public.pem -outform PEM -pubout
{% endcodeblock %}


### Deploy the public key on the managed nodes

The public key in this example is `noc-public.pem`

Deploy it in  `/etc/mcollective/ssl/clients/`

Mode `0644`

You can use a puppet class for automatic deployment.

For an example, check :

[https://github.com/thinkfr/puppetclasses/blob/master/manifests/classes/mcollective.pp](https://github.com/thinkfr/puppetclasses/blob/master/manifests/classes/mcollective.pp)

### Install the mcollective-client package

On your client node(s) only.

{% codeblock lang:sh %}
yum -y install mcollective-client
{% endcodeblock %}


### Create a client configuration

On your client node(s) only.

This is usually `/etc/mcollective/client.cfg`

For example :

{% codeblock lang:sh %}
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
logfile = /dev/null
loglevel = info

# Plugins
securityprovider = ssl
plugin.ssl_server_public = /etc/mcollective/ssl/server-public.pem
plugin.ssl_client_private = /root/noc-private.pem
plugin.ssl_client_public = /etc/mcollective/ssl/clients/noc-public.pem 

connector = stomp
plugin.stomp.host = mqbroker.labolinux.fr
plugin.stomp.port = 6163
plugin.stomp.user = noc 
plugin.stomp.password = nocpassword

# Facts
factsource = facter 
plugin.yaml = /etc/mcollective/facts.yaml
{% endcodeblock %}

Put the `noc-private.pem` key where you set it with the parameter
`plugin.ssl_client_private`

If you use subcollectives, you'll need to change the settings of
`main_collective` and `collectives`

For subcollectives, refer to [Clustering of the MQ broker](http://www.kermit.fr/documentation/mcollective/cluster.html). This is discussed in the section about security.


### Give it a try

On your client node, run :

{% codeblock lang:sh %}
mco ping
{% endcodeblock %}



