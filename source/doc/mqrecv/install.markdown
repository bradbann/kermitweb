---
layout: page
title: "Message Queue"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Purpose

Kermit use some queues to collect data like inventories and logs from the managed nodes.

You need to install a receiver daemon on one of your nodes to collect the data.

## Install the packages

Install `kermit-mqrecv` only on one node.

Install `kermit-mqsend` on all nodes.

With the kermit yum repository (see: [Using the kermit repository](/doc/using_the_repo.html)) set :

{% codeblock lang:sh %}
yum -y install kermit-mqrecv 

#Installing:
# kermit-mqrecv
#Installing for dependencies:
# rubygem-daemons 
{% endcodeblock %}


## Create the SSL keys for communication

{% codeblock lang:sh %}
/usr/local/bin/kermit/queue/genkey.sh
{% endcodeblock %}

Generates `/tmp/q-private.pem` and `/tmp/q-public.pem`

<div class="important" markdown='1'>
Deploy the public key ONLY on the receiver node (the consumer).

Deploy the private key ONLY on the sending nodes (the publishers, aka the managed nodes).
</div>

So here :

{% codeblock lang:sh %}
mkdir -p /etc/kermit/ssl/
cp /tmp/q-public.pem /etc/kermit/ssl
{% endcodeblock %}



## Configuration

### For all nodes

In `/etc/kermit/kermit.cfg`, you need :

{% codeblock lang:ini %}
[amqpqueue]
outputdir = /var/lib/kermit/queue 
amqpcfg = /etc/kermit/amqpqueue.cfg
inventoryqueuename = /queue/kermit.inventory
logqueuename = /queue/kermit.log

{% endcodeblock %}

You can get a template for `/etc/kermit/amqpqueue.cfg` here :

[https://raw.github.com/lofic/ipc/master/tuto/mcollective-simple\_queue/standalone\_ver/amqpqueue.cfg](https://raw.github.com/lofic/ipc/master/tuto/mcollective-simple_queue/standalone_ver/amqpqueue.cfg)

In `amqpqueue.cfg`, set `plugin.stomp.host` to your MCollective AMQP broker.

### On the message broker

You must set a specific ACL for the consumer on the broker.

If you use RabbitMQ :

{% codeblock lang:sh %}
rabbitmqctl set_permissions -p '/' mcollective ".*" ".*" ".*"
{% endcodeblock %}


If you use ActiveMQ, set in `/etc/activemq/activemq.xml` :

{% codeblock lang:xml %}
<authorizationEntries>
    <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
    <authorizationEntry queue=">" write="mcollective" read="mcollective" admin="mcollective" />
    <!-- ... -->
</authorizationEntries>
{% endcodeblock %}


(this should be refined)

And restart the ActiveMQ service.


### On the queue consumer node

Create the output folders for the queues :

{% codeblock lang:sh %}
mkdir -p /var/lib/kermit/queue/kermit.inventory
mkdir -p /var/lib/kermit/queue/kermit.log
chown nobody /var/lib/kermit/queue/kermit.inventory
chown nobody /var/lib/kermit/queue/kermit.log
{% endcodeblock %}

 
Enable and start the daemons :

{% codeblock lang:sh %}
/sbin/chkconfig --add kermit-inventory
/sbin/chkconfig --add kermit-log
/sbin/chkconfig kermit-inventory on
/sbin/chkconfig kermit-log on
/sbin/service kermit-inventory start
/sbin/service kermit-log start
{% endcodeblock %}


## Deploy the configuration and keys with puppet

Puppet resources and classes :

{% codeblock  %}
/etc/puppet/manifests/classes/kermit.pp
/etc/puppet/manifests/classes/yum.pp

/etc/puppet/modules/kermit/files/amqpqueue.cfg
/etc/puppet/modules/kermit/files/kermit.cfg
/etc/puppet/modules/kermit/files/q-private.pem
/etc/puppet/modules/yum/files/kermit.repo
{% endcodeblock %}


You can use the templates from [https://github.com/kermitfr/puppetclasses](https://github.com/kermitfr/puppetclasses) 

But you'll have to set your own `.pem` keys and certificates.



## Troubleshooting

You can run the consumer in a console.

For example :

{% codeblock lang:sh %}
/sbin/service kermit-inventory stop
ruby /usr/local/bin/kermit/queue/recv.rb /queue/kermit.inventory
{% endcodeblock %}


and/or

{% codeblock lang:sh %}
/sbin/service kermit-log stop
ruby /usr/local/bin/kermit/queue/recv.rb /queue/kermit.log
{% endcodeblock %}

Send some messages from a publisher with :

{% codeblock lang:sh %}
ruby /usr/local/bin/kermit/queue/send.rb /path/to/json_file

ruby /usr/local/bin/kermit/queue/sendlog.rb path/to/log_file
{% endcodeblock %}

You can also test the communication with standalone publisher and consumer
scripts :

[https://github.com/lofic/ipc/tree/master/tuto/mcollective-simple\_queue/standalone\_ver](https://github.com/lofic/ipc/tree/master/tuto/mcollective-simple_queue/standalone_ver)

Stop the services `kermit-inventory` and `kermit-log` before using that.

