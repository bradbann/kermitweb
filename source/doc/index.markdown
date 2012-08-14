---
layout: page
title: "documentation"
comments: true
sharing: true
footer: true
sidebar: false 
---

##The Big Picture

[Presentation (work in progress)](http://www.kermit.fr/documentation/prez/prez.pdf)

[Architecture diagram](/images/bigpicture/bigpicture.png)

[Get started](/doc/getstarted.html)

##Installing the packages

[Using the kermit repository](/doc/using_the_repo.html)

##MCollective framework

For the messaging backend of MCollective you can choose the ActiveMQ or RabbitMQ
implementations of AMQP.

<div class="important" markdown='1'>
But YOU SHOULD PICK ACTIVEMQ if you plan to have clustered AMQP broker nodes 
on a WAN and if you don't master RabbitMQ.
</div>

More details about this [here](http://www.kermit.fr/documentation/mcollective/cluster.html)


[Installation of the message broker - activemq version](/doc/mcollective/broker_activemq_install.html)

[Installation of the message broker - rabbitmq version](http://www.kermit.fr/documentation/mcollective/broker_rabbitmq_install.html)

<div class="important" markdown='1'>
This installation procedure is fine for testing. But on a production system, you MUST secure your platform.  Read why and how below.
</div>


[SSL configuration deployment for message signing and identification](http://www.kermit.fr/documentation/mcollective/ssl.html)

[Configuration of a client (a management node)](http://www.kermit.fr/documentation/mcollective/client.html)

[Clustering of the MQ for the management of multiple datacenters](http://www.kermit.fr/documentation/mcollective/cluster.html)


##Network Operation Center (NOC)

The components are :

*  a puppet master for deploying the agents, keys, and configurations
*  a specific MCollective node with a key to manage other nodes
*  a custom message queue for receiving information like inventories
*  a Web user interface (Web UI)
*  a REST service for flexible communication with the backend

These components can be installed on separate systems for scalability.

##Puppet master

[Installation](http://www.kermit.fr/documentation/puppet/install.html)


##Web UI

[Installation](http://www.kermit.fr/documentation/webui/install.html)

[Update](http://www.kermit.fr/documentation/webui/update.html)

[User guide](http://www.kermit.fr/documentation/webui/userguide.html)


##REST server

[Installation](http://www.kermit.fr/documentation/restmco/install.html)


##Message Queue Subscriber

[Installation](http://www.kermit.fr/documentation/mqrecv/install.html)


Managed system nodes
--------------------

[RHEL/Centos 4, 5, 6](http://www.kermit.fr/documentation/mcollective/rhel_install.html)

[AIX 6.1 - MCollective agent](http://www.kermit.fr/documentation/mcollective/aix_install.html)

[Windows - MCollective agent](/doc/mcollective/windows_install.html)

[AIX 6.1 - Puppet client](http://www.kermit.fr/documentation/puppet/aix_install.html)

