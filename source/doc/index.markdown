---
layout: page
title: "documentation"
comments: true
sharing: true
footer: true
sidebar: false 
---

## The Big Picture

[Presentation (work in progress)](http://www.kermit.fr/documentation/prez/prez.pdf)

[Architecture diagram](/images/bigpicture/bigpicture.png)

[Get started](/doc/getstarted.html)

## Installing the packages

[Using the kermit repository](/doc/using_the_repo.html)

## MCollective framework

### Message broker
For the messaging backend of MCollective you can choose the ActiveMQ or RabbitMQ
implementations of AMQP.

<div class="important" markdown='1'>
But YOU SHOULD PICK ACTIVEMQ if you plan to have clustered AMQP broker nodes 
on a WAN and if you don't master RabbitMQ.
</div>

More details about this [here](/doc/mcollective/cluster.html)


[Installation of the message broker - activemq version](/doc/mcollective/broker_activemq_install.html)

[Installation of the message broker - rabbitmq version](/doc/mcollective/broker_rabbitmq_install.html)

### Managed system nodes

[RHEL/Centos 4, 5, 6](/doc/mcollective/rhel_install.html)

[AIX 6.1 - MCollective agent](/doc/mcollective/aix_install.html)

[Windows - MCollective agent](/doc/mcollective/windows_install.html)

[AIX 6.1 - Puppet client](/doc/puppet/aix_install.html)

[Automatic deployment](/doc/mcollective/autodeploy.html)


### Management node

[Configuration of a client (a management node)](/doc/mcollective/client.html)

### Production

<div class="important" markdown='1'>
This installation procedure is fine for testing. But on a production system, you MUST secure your platform.  Read why and how below.
</div>
[SSL configuration deployment for message signing and identification](/doc/mcollective/ssl.html)

[Clustering of the MQ for the management of multiple datacenters](/doc/mcollective/cluster.html)



## Network Operation Center (NOC)

The components are :

*  a puppet master for deploying the agents, keys, and configurations
*  a specific MCollective node with a key to manage other nodes
*  a custom message queue for receiving information like inventories
*  a Web user interface (Web UI)
*  a REST service for flexible communication with the backend

These components can be installed on separate systems for scalability.

## REST server

[Installation](/doc/restmco/install.html)

## Web UI

[Installation](/doc/webui/install.html)

[Update](/doc/webui/update.html)

[User guide](/doc/webui/userguide.html)

## Message Queue Subscriber

[Installation](/doc/mqrecv/install.html)

## Puppet master

[Installation](/doc/puppet/install.html)


## General troubleshooting

[Troubleshooting](/doc/troubleshooting.html)



