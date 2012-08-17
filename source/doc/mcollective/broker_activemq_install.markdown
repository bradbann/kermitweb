---
layout: page
title: "Install the message broker"
comments: true
sharing: true
footer: true
sidebar: false 
---

You can use ActiveMQ or RabbitMQ.

<div class="important" markdown='1'>
Since MCollective 2.0 it is strongly recommended to use ActiveMQ, unless
you know exactly what you're doing.
</div>

The procedure below is for ActiveMQ or RHEL/Centos 5 and 6 x86\_64


## Sources of information

This installation procedure is inspired with [MCollective - Getting started](http://docs.puppetlabs.com/mcollective/reference/basic/gettingstarted.html#download-and-install)


## Get the packages

See [Using the kermit repository](/doc/using_the_repo.html)


## el5/el6 x86\_64

### Install some packages from the base RHEL or Centos repository

Those packages are required as dependencies.

{% codeblock lang:sh %}
yum -y install java-1.6.0-openjdk 
{% endcodeblock %}


### Install ActiveMQ

ActiveMQ will be used as the middleware messaging backend for MCollective.

Install this ONLY ON ONE NODE (except if you set a cluster).

For example install the MQ broker on the system used to manage the other nodes.

But for a purpose of scalability you can put the broker and the MCollective
clients (the management nodes) on separate systems.


#### Install the packages 

{% codeblock lang:sh %}
yum -y install tanukiwrapper activemq activemq-info-provider 
{% endcodeblock %}

This is the official release from puppetlabs ([http://yum.puppetlabs.com/](http://yum.puppetlabs.com/)).


#### Configure ActiveMQ

The main configuration file is `/etc/activemq/activemq.xml` 

Add or modify a user and password for MCollective in the section
`<simpleAuthenticationPlugin>`

{% codeblock lang:xml %}
<simpleAuthenticationPlugin>
  <users>
    <!-- ... -->
    <authenticationUser username="mcollective" password="marionette"
                        groups="mcollective,admins,everyone"/>
  </users>
</simpleAuthenticationPlugin>
{% endcodeblock %}


Add or modify some ACLs on the MCollective topics and queues in the section
`<authorizationPlugin>` 

{% codeblock lang:xml %}
<authorizationPlugin>
  <map>
    <authorizationMap>
      <authorizationEntries>
        <!-- ... -->
        <authorizationEntry queue=">" write="mcollective" read="mcollective"
                                      admin="mcollective" />
        <!-- ... -->
        <authorizationEntry topic="mcollective.>" write="mcollective"
                                       read="mcollective" admin="mcollective" />
        <!-- ... -->
      </authorizationEntries>
    </authorizationMap>
  </map>
</authorizationPlugin>
{% endcodeblock %}

Configure a stomp listening port in the section `transportConnectors`  

Set the port to 6163

{% codeblock lang:xml %}
<transportConnectors>
    <transportConnector name="openwire" uri="tcp://0.0.0.0:6166"/>
    <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:6163"/>
</transportConnectors>
{% endcodeblock %}


#### Tune ActiveMQ

Increase the memory maximum for the JVM of ActiveMQ if there are many nodes to
handle.

10 MB per node.

For 200 nodes, set 2048 MB.

In `/etc/activemq/activemq-wrapper.conf` :

{% codeblock lang=sh %}
wrapper.java.maxmemory=2048
{% endcodeblock %}

If you have many nodes you could also find useful to disable the flow control.

In `/etc/activemq/activemq.xml` : 

{% codeblock lang:xml %}
<destinationPolicy>
    <policyMap>
      <policyEntries>
        <policyEntry topic=">" producerFlowControl="false" memoryLimit="1mb">
          <!-- ... -->
        </policyEntry>
        <policyEntry queue=">" producerFlowControl="false" memoryLimit="1mb">
          <!-- ... -->
        </policyEntry>
      </policyEntries>
    </policyMap>
</destinationPolicy>
{% endcodeblock %}


You can also tune the limits of the section `<systemUsage>` in 
`/etc/activemq/activemq.xml`.

To monitor the resource used with the ActiveMQ Console, see the URL below in 'Test the configuration'.

#### Open some firewall ports

TCP ports 6163, 6166 and 8161.

With the basic RHEL/Centos 6 firewall, in `/etc/sysconfig/iptables` add those rules at the right place in the chain :

{% codeblock sh %}
-A INPUT -m state --state NEW -m tcp -p tcp --dport 6163 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 6166 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 8161 -j ACCEPT
{% endcodeblock %}

And restart the firewall :

{% codeblock lang:sh %}
/sbin/service iptables restart
{% endcodeblock %}


#### Enable and start the service

{% codeblock lang:sh %}
/sbin/chkconfig activemq on
/sbin/service activemq restart
{% endcodeblock %}


#### Test the configuration

ActiveMQ (Web) Console :

[http://your\_broker\_fqdn:8161/admin/](http://your_broker_fqdn:8161/admin/)


