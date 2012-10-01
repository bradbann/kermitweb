---
layout: page
title: "Install the message broker"
comments: true
sharing: true
footer: true
sidebar: false 
---

You can use ActiveMQ or RabbitMQ.

Note : since MCollective 2.0 it is strongly recommended to use ActiveMQ, unless you know exactly what you're doing.

The procedure below is for RabbitMQ or RHEL/Centos 5 x86\_64


## Sources of information

This installation procedure is inspired with :

* [Running MCollective with RabbitMQ on CentOS](http://flybyunix.carlcaum.com/2011/02/running-mcollective-with-rabbitmq-on.html)

* [Mcollective and RabbitMQ on Centos](http://www.threedrunkensysadsonthe.net/2010/12/mcollective-and-rabbitmq-on-centos)

* [MCollective - Getting started](http://docs.puppetlabs.com/mcollective/reference/basic/gettingstarted.html#mcollective)


## Get the packages

See [Using the kermit repository](/doc/using_the_repo.html)


## el5 x86\_64

### Install some packages from the base RHEL or Centos repository

Those packages are required as dependencies.

{% codeblock lang:sh %}
yum -y install tk unixODBC
{% endcodeblock %}



### Install RabbitMQ

RabbitMQ will be used as the middleware messaging backend for MCollective.

Install this ONLY ON ONE NODE (except if you set a cluster).

For example install the MQ broker on the system used to manage the other nodes.

But for a purpose of scalability you can put the broker and the MCollective
clients (the management nodes) on separate systems.


#### Install Erlang

Package : `erlang`

Erlang is required for RabbitMQ.

Quote from [http://www.rabbitmq.com/server.html](http://www.rabbitmq.com/server.html) :

> Note to users of RHEL 5 and derived distributions (e.g. CentOS 5): Due to the
> EPEL package update policy, EPEL 5 contains Erlang version R12B-5, which is
> relatively old. rabbitmq-server supports R12B-5, but performance may be lower
> than for more recent Erlang versions, and certain non-core features are not
> supported (SSL support, HTTP-based plugins). Therefore, we recommend that you
> install the most recent stable version of Erlang

You can install a recent erlang on RHEL5/Centos 5 from :

* [http://repos.fedorapeople.org/repos/peter/erlang/](http://repos.fedorapeople.org/repos/peter/erlang/)

* [http://www.kermit.fr/stuff/yum.repos.d/erlangR14-el5-x86\_64.repo](http://www.kermit.fr/stuff/yum.repos.d/erlangR14-el5-x86_64.repo)


#### Install rabbitmq-server

Install rabbitmq-server 2.7.1+

{% codeblock lang:sh %}
yum -y install rabbitmq-server # 2.7.1+
rabbitmq-plugins enable amqp_client
rabbitmq-plugins enable rabbitmq_stomp
cat /etc/rabbitmq/enabled_plugins
{% endcodeblock %}


`rabbitmq-server` is the official release from rabbitmq.com.


#### Configure RabbitMQ

Create `/etc/rabbitmq/rabbitmq-env.conf` to set the stomp listener, with :

{% codeblock %}
SERVER_START_ARGS="-rabbitmq_stomp tcp_listeners [{\"0.0.0.0\",6163}]"
{% endcodeblock %}


Start RabbitMQ :

{% codeblock lang:sh %}
/sbin/service rabbitmq-server restart
{% endcodeblock %}


Add a mcollective user and password :

{% codeblock lang:sh %}
rabbitmqctl delete_user guest
rabbitmqctl add_user mcollective marionette
{% endcodeblock %}


Set mcollective permissions :

{% codeblock lang:sh %}
rabbitmqctl set_permissions -p / mcollective "^amq.gen-.*" ".*" ".*"
{% endcodeblock %}


### Enable and start the service

{% codeblock lang:sh %}
/sbin/chkconfig rabbitmq-server on
/sbin/service rabbitmq-server restart
{% endcodeblock %}



