---
layout: page
title: "get started"
comments: true
sharing: true
footer: true
sidebar: false 
---


## 1. Configure the package repositories

If you don't want to bother collecting the packages, you can use the kermit repositories where we put all the needed packages.

So start with [Using the kermit repository](/doc/using_the_repo.html)

We provide package repositories for Centos/RHEL 4,5,6. 

We provide packages for AIX and Windows.

Unfortunately the WebUI still needs a RHEL/Centos 5. We're working on this, it should be available for RHEL6/Centos 6 soon.

## 2. Install a message broker

The WebUI is a frontend for MCollective, and MCollective uses a message broker for communication.

This is :

[Install the message broker](/doc/mcollective/broker_activemq_install.html)

Or you can also use the official MCollective documentation :

[MCollective - Getting started](http://docs.puppetlabs.com/mcollective/reference/basic/gettingstarted.html#download-and-install)

## 3. Install MCollective

### Managed nodes

There should be a MCollective Daemon on each node.

[Installation on Centos/RHEL 4,5,6](/doc/mcollective/rhel_install.html)

[Installation on Windows](/doc/mcollective/windows_install.html)

[Installation on AIX 6.1](/doc/mcollective/aix_install.html)

### Management node

A management node is just a MCollective client. On this node you install the `mcollective-client` package in addition to the `mcollective-server` package. You'll need at least one. 

IF you use the SSL security plugin the client node will need a special key to let other nodes respond to its queries. See the advanced topics section for SSL configuration. This is not required for a test or demo installation.

[Configuration of a client](/doc/mcollective/client.html)

Then if you `mco ping` from the client node and get an answer from the managed nodes, you can go to the next step.

## 4. Install the REST server

This component is used by the WebUI to send queries and get responses to MCollective.

For a simple installation you can install the REST server and the WebUI on the same system.

[REST server](/doc/restmco/install.html)

When the tests of the REST server are fine, you can install the WebUI.

## 5. Install the WebUI

[Web UI](/doc/webui/install.html)

To see the nodes on the WebUI, you'll also need to install some specific MCollective agents on the managed nodes :

* `mcollective-plugins-nodeinfo`
* `mcollective-plugins-agentinfo`

Go to the admin dashboard of Kermit and launch :

* Refresh Server Basic Info
* Update Agents info

(cf [this video](http://www.youtube.com/watch?v=cN-ZmtemdMI&list=PLE6AD5E02BB4B773D&index=4&feature=plpp_video))

## 6. Advanced topics

That's for a start.

If you want to be able to collect data like inventories and logs from the managed nodes, you should also [Install the message queue subscriber](/doc/mqrecv/install.html).


If you want to manage nodes on multiple datacenters, you can [Make a cluster of message brokers](http://www.kermit.fr/documentation/mcollective/cluster.html).


For a production environment you'll need additional security settings (see [SSL configuration deployment for message signing and identification](/doc/mcollective/ssl.html)).


Puppet is optional. It helps deploying the configuration on the systems but you can do all manually for a start.
When you're familiar with the concepts and the manual procedure, you can write your puppet classes for automatic deployment.

[Automatic deployment](/doc/mcollective/autodeploy.html)

[Some puppet classes for automatic deployment](https://github.com/thinkfr/puppetclasses).

