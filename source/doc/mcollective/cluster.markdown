---
layout: page
title: "Scalability and availability"
comments: true
sharing: true
footer: true
sidebar: false 
---


We will achieve this with a MQ cluster.

The MQ (message queuing) cluster can be used for :

* redundancy of the message broker

* replication of the messages across multiple bastions and datacenters


## Architecture

Here is the architecture for multiple datacenters :

{% img /images/mcol-cluster.png 521 372 MQ cluster %}


## Choice of ActiveMQ


<div class="important" markdown='1'>
YOU SHOULD PICK ACTIVEMQ if you plan to have clustered AMQP broker nodes on a
WAN and if you don't master RabbitMQ.
</div>

ATOW (Nov. 2011), the RabbitMQ cluster implementation is not recommended for our
particular purpose for multiple reasons :

* it is not reliable on a WAN 
 
> RabbitMQ clustering does not tolerate network partions well, so it should not be used over a WAN.
 
* the RabbitMQ Federation plugin is a better solution for connecting brokers
across a WAN, but it is very new and still lacks extensive documentation,
especially in the context of MCollective. And a client connecting to any broker
can only see queues in that broker (MCollective use topics but we add some
custom queues in Kermit). 

The README says :
> this is all somewhat experimental. There hasn't been much real-world testing

* ActiveMQ cluster is reported to behave fine on a WAN and with many nodes

* ActiveMQ cluster for the purpose of MCollective is well documented

* RabbitMQ with the STOMP plugin does not generate predictable topic names (
ActiveMQ with STOMP and MCollective does). With RabbitMQ the topic names are
`amq.gen-.*`

This does not allow fine grained ACLs (i.e. on subcollectives)

For more information on this, check :

* [RabbitMQ Clustering Guide](http://www.rabbitmq.com/clustering.html)

* [Federation plugin README](http://hg.rabbitmq.com/rabbitmq-federation/file/default/README)

* [Federation plugin preview release](http://www.rabbitmq.com/blog/2011/06/22/federation-plugin-preview-release/)

* [mcollective-users - RabbitMQ WAN clustering considered harmful](http://groups.google.com/group/mcollective-users/browse_thread/thread/fd42a4c02819e101)

* [mcollective-users - Load Balancing a Message Queue Cluster](http://groups.google.com/group/mcollective-users/msg/2f903c2e9588ac3a)


## Implementation with ActiveMQ

It is described here :

[ActiveMQ Clustering](http://www.devco.net/archives/2009/11/10/activemq_clustering.php)

Check some configuration examples with various topologies at :

[ActiveMQ examples](https://github.com/puppetlabs/marionette-collective/tree/master/ext/activemq/examples/)

The steps for RHEL 5/6 and a 2 node ActiveMQ cluster are described below.

## Install new ActiveMQ brokers

As already described [here](/doc/mcollective/broker_activemq_install.html)

Do only the section 'Install ActiveMQ'.


### Clusterize the ActiveMQ brokers

#### Stop all the ActiveMQ brokers

{% codeblock lang:sh %}
/sbin/service activemq stop
{% endcodeblock %}


#### Set the cluster

On our example the 2 cluster node hostnames are mqbroker01 and mqbroker02 

We will use a dedicated mq user for the connection : mqcluster

Set `/etc/activemq/activemq.xml`

On the first cluster node :

{% codeblock lang:xml %}
<broker xmlns="http://activemq.apache.org/schema/core"
        brokerName="mqbroker01" dataDirectory="${activemq.base}/data"
        destroyApplicationContextOnStop="true">

<!-- ... -->

<managementContext>
  <!-- ... -->
</managementContext>

<networkConnectors>
  <networkConnector name="amq1-amq2" uri="static:(tcp://mqbroker02:6166)"
                    userName="mqcluster" password="whatever"
                    duplex="true" suppressDuplicateQueueSubscriptions="true"
                    networkTTL="2"/>
</networkConnectors>

<!-- ... -->

<simpleAuthenticationPlugin>
  <users>
    <!-- ... -->
    <authenticationUser username="mqcluster" password="whatever"
                        groups="admins,everyone"/>
  </users>
</simpleAuthenticationPlugin>

<transportConnectors>
  <transportConnector name="openwire" uri="tcp://0.0.0.0:6166"/>
  <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:6163"/>
</transportConnectors>

</broker>
{% endcodeblock %}

On the second cluster node :

{% codeblock lang:xml %}
<broker xmlns="http://activemq.apache.org/schema/core"
        brokerName="mqbroker02" dataDirectory="${activemq.base}/data"
        destroyApplicationContextOnStop="true">

<!-- ... -->

<managementContext>
  <!-- ... -->
</managementContext>

<networkConnectors>
  <networkConnector name="amq2-amq1" uri="static:(tcp://mqbroker01:6166)"
                    userName="mqcluster" password="whatever"
                    duplex="true" suppressDuplicateQueueSubscriptions="true"
                    networkTTL="2"/>
</networkConnectors>

<!-- ... -->

<simpleAuthenticationPlugin>
  <users>
    <!-- ... -->
    <authenticationUser username="mqcluster" password="whatever"
                        groups="admins,everyone"/>
  </users>
</simpleAuthenticationPlugin>

<transportConnectors>
  <transportConnector name="openwire" uri="tcp://0.0.0.0:6166"/>
  <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:6163"/>
</transportConnectors>

</broker>
{% endcodeblock %}

#### Enable and start the clustered brokers

{% codeblock lang:sh %}
/sbin/service activemq start
/sbin/chkconfig activemq on
{% endcodeblock %}



### Configure the MCollective nodes

...to use one of the clustered broker.

In `/etc/mcollective/server.cfg` of the managed nodes, change `plugin.stomp.host`


### Automatic deployment of the cluster configuration

You could use in a puppet class :

{% codeblock lang:rb %}
class activemq {

    package { "java-1.6.0-openjdk":
        ensure  => installed,
    }

    package { "tanukiwrapper":
        ensure  => installed,
        require => [ Package["java-1.6.0-openjdk"],
                     File["/etc/yum.repos.d/kermit.repo"] ],
    }

    package { "activemq":
        ensure  => installed,
        require => Package["tanukiwrapper"],
    }

    package { "activemq-info-provider":
        ensure  => installed,
        require => Package["activemq"],
    }

    file { "/etc/activemq/activemq.xml":
        ensure  => present,
        content => template("activemq/activemq.xml"),
        mode    => 0644,
        owner   => "root",
        group   => "root",
        require => Package["activemq-info-provider"],
        notify  => Service["activemq"],
    }

    service { "activemq":
        ensure  => running,
        enable  => true,
        require => [Package["activemq-info-provider"],
                    File["/etc/activemq/activemq.xml"] ],
    }

}
{% endcodeblock %}

And in your template for `activemq.xml` :

{% codeblock lang:xml %}
<!-- ... -->

<broker xmlns="http://activemq.apache.org/schema/core"
        brokerName="<%= hostname %>"
        dataDirectory="${activemq.base}/data" destroyApplicationContextOnStop="true">

<!-- ... -->

  <managementContext>
    <!-- ... -->
  </managementContext>

  <% if ipaddress == mqbrokerip01 then %>
  <networkConnectors>
     <networkConnector name="amq1-amq2" uri="static:(tcp://<%= mqbrokerip02 %>:6166)" 
                       userName="mqcluster" password="whatever" duplex="true"
                       suppressDuplicateQueueSubscriptions="true" networkTTL="2"/>
  </networkConnectors>
  <% end %>

  <% if ipaddress == mqbrokerip02 then %>
  <networkConnectors>
     <networkConnector name="amq2-amq1" uri="static:(tcp://<%= mqbrokerip01 %>:6166)"
                       userName="mqcluster" password="whatever" duplex="true" 
                       suppressDuplicateQueueSubscriptions="true" networkTTL="2"/>
  </networkConnectors>
  <% end %>


<!-- ... -->

</broker>

<!-- ... -->
{% endcodeblock %}

Just define somewhere in your puppet declarations `$mqbrokerip01` and `$mqbrokerip02`


## Security

In a context with multiple environments and datacenters, where administrators
have restricted scopes, you need to be very careful about security.

You can set ACLs in the web UI to restrict the scope of actions and machines.

But you should also restrict the access to the MCollective backend.

You should :

* restrict the access to the console of the systems where you have some
MCollective client keys
* protect the access to the client keys
* restrict the scope of the MCollective clients, keys, and users 

Some basic steps are :

* use some firewalling rules for the MQ brokers and MCollective clients 
* set the sshd\_config directives AllowGroups and AllowUsers
* set some sudoers rules on the MCollective client systems 
* carefully set the permissions for the MCollective client private keys
* use subcollectives to reduce scopes 
* set different MQ users and some ACLs on the subcollectives



### Firewall

To communicate with each other, the clustered brokers use

* TCP port 6166 for openwire (used for the cluster communication)
* TCP port 6163 for stomp (in our configuration)

So you need to configure a rule for these ports on the firewalls between the
brokers. Authorize both ways.

The configured stomp port is set with  `plugin.stomp.port` in `/etc/mcollective/server.cfg` on any node.


### Bastion

You can improve the security of the brokers and MCollective clients with a
local firewall.

This is an example of configuration with default policies = DROP :

{% codeblock lang:sh %}
ipt=/sbin/iptables
# Reset all 
$ipt -t filter -F
$ipt -t nat -F
$ipt -X

# Default policies 
$ipt -P INPUT   DROP
$ipt -P OUTPUT  DROP
$ipt -P FORWARD DROP

# Loopback interface
$ipt -A INPUT  -i lo -j ACCEPT
$ipt -A OUTPUT -o lo -j ACCEPT

# Already authorized connections 
$ipt -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$ipt -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ping OK
$ipt -A INPUT  -p icmp --icmp-type echo-request -j ACCEPT
$ipt -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# Authorizations on INPUT
$ipt -A INPUT -m state --state NEW -p tcp --dport 22   -j ACCEPT # SSH
$ipt -A INPUT -m state --state NEW -p tcp --dport 6163 -j ACCEPT # stomp
$ipt -A INPUT -m state --state NEW -p tcp --dport 6166 -j ACCEPT # openwire

# Authorizations on OUTPUT
$ipt -A OUTPUT -m state --state NEW -p tcp --dport 22   -j ACCEPT # SSH
$ipt -A OUTPUT -m state --state NEW -p tcp --dport 6163 -j ACCEPT # stomp
$ipt -A OUTPUT -m state --state NEW -p tcp --dport 6166 -j ACCEPT # openwire
$ipt -A OUTPUT -m state --state NEW -p tcp --dport 8140 -j ACCEPT # Puppet
$ipt -A OUTPUT -m state --state NEW -p tcp --dport 53   -j ACCEPT # DNS TCP
$ipt -A OUTPUT -m state --state NEW -p udp --dport 53   -j ACCEPT # DNS UDP

# Save rules 
/sbin/service iptables save active
{% endcodeblock %}


### SSH ACL

Configure the file `/etc/ssh/sshd_config`

Directive `AllowUsers` :

> This keyword can be followed by a list of user name patterns, separated by
> spaces.
> 
> If specified, login is allowed only for user names that match one
> of the patterns.
> 
> ‘\*’ and ‘?’ can be used as wildcards in the patterns.
> 
> Only user names are valid; a numerical user ID is not recognized.  By
> default, login is allowed for all users.
> If the pattern takes the form USER@HOST then USER and HOST are separately
> checked, restricting logins to particular users from particular hosts.

Directive `AllowGroups` :

> This keyword can be followed by a list of group name patterns, separated by
spaces.
> 
> If specified, login is allowed only for users whose primary group or
supplementary group list matches one of the patterns.
> 
> ‘\*’ and ‘?’ can be used as wildcards in the patterns.
> Only group names are valid; a numerical group ID is not recognized.
>
> By default, login is allowed for all groups.

Directive `PermitRootLogin` :

> Specifies whether root can log in using ssh(1).  The argument must be
> “yes”, “without-password”, “forced-commands-only”, or “no”.
> 
> The default is “yes”.
> 
> If this option is set to “without-password”, password authentication is
> disabled for root.
> 
> (...)
> 
> If this option is set to “no”, root is not allowed to log in.

You should use 'no' or 'without-password'.

### Sudoers

Set the owner and group ownership of your MCollective client private keys
to `root:root`

Set the permissions to `0600` on the private keys (cf
`plugin.ssl_client_private` in the client configuration file)

Restrict the switch user permissions in `/etc/sudoers`, for example :

{% codeblock %}
User_Alias MCOLADM=pim,pam,poum
Cmnd_Alias SU=/bin/su
SYSADM   ALL=(ALL) NOPASSWD: SU
{% endcodeblock %}

You can refine this with rules on the `/usr/sbin/mc-rpc`, `/usr/bin/mco` and
other MCollective client commands.


### Subcollectives

The Kermit Web UI run actions on the backend through a REST server.

The REST server needs a MCollective client configuration with an access to all
the nodes.

This is required if you want to have a view of all your systems and environments
from a single WebUI.

You will set some ACLs in the Web UI to control which users have access to which
systems to do which actions.

But if you use also MCollective directly on the backend, and if you have
multiple environment scopes (i.e. development, quality assessment, production)
with multiple administrator scopes, you should use subcollectives. 

For example you don't want a QA administrator to accidentally mess-up with your
production.

Subcollectives let you define sub-scopes of systems.

You can refer to :

[Subcollectives](http://docs.puppetlabs.com/mcollective/reference/basic/subcollectives.html)

[Subcollectives for security](http://puppetlabs.com/blog/using-mcollective-1-1-3-subcollectives-for-security/)

In our example, we'll define :

* a main collective for the WebUI and full scope
* a subcollective for the QA environment
* a subcollective for the production environment

And 3 MCollective server and client configurations to match the 3 scopes.

#### Configuration of the managed nodes

This is in `server.cfg`

For the QA systems, in `/etc/mcollective/server.cfg`, we set :

{% codeblock lang:ini %}
main_collective = mcollective
collectives = mcollective, qacollective
{% endcodeblock %}

For the production systems, we set :

{% codeblock lang:ini %}
main_collective = mcollective
collectives = mcollective, prodcollective
{% endcodeblock %}

You can easily deploy this with Puppet. For example you can set in a Puppet
class :

{% codeblock lang:rb %}
file { "/etc/mcollective/server.cfg":
        ensure => present,
        mode   => 640,
        owner  => root,
        group  => root,
        source => $environment ? {
            'qa'          => "puppet:///modules/mcollective/serverqa.cfg",
            'production'  => "puppet:///modules/mcollective/serverprod.cfg",
        },
        require => Package["mcollective-common"],
    }
{% endcodeblock %}

#### Configuration of management nodes

In our example, We use 3 client configurations (`/etc/mcollective/client.cfg`),
depending on the administration scope.

Full-scope client :

{% codeblock lang:ini %}
main_collective = mcollective
collectives = mcollective, qacollective, prodcollective
{% endcodeblock %}

You can use a subscope with :

{% codeblock lang:sh %}
mco ping -T qacollective
{% endcodeblock %}

QA client :


{% codeblock lang:ini %}
main_collective = qacollective
collectives = qacollective
{% endcodeblock %}

Production client :

{% codeblock lang:ini %}
main_collective = prodcollective
collectives = prodcollective
{% endcodeblock %}

In addition, you could use different users and different client keys, with the
parameters :

{% codeblock lang:ini %}
plugin.ssl_client_private = ...
plugin.ssl_client_public = ...

plugin.stomp.user = ...
plugin.stomp.password = ...
{% endcodeblock %}

Deploy the public part of the key used by the qa client only on the qa nodes.

Deploy the public part of the key used by the production client only on the
production nodes.

Create the MQ users in `/etc/activemq/activemq.xml`. For example : 

{% codeblock lang:xml %}
<simpleAuthenticationPlugin>
  <users>
    <!-- ... -->
    <authenticationUser username="qaadmin" password="muppetsfromspace"
                        groups="mcollective,admins,everyone"/>
    <authenticationUser username="prodadmin" password="poobatron"
                        groups="mcollective,admins,everyone"/>
  </users>
</simpleAuthenticationPlugin>
{% endcodeblock %}

TODO : describe the ACLS for those users and subcollective topics.

To create a complete MCollective client configuration, refer to :

[Configuration of a client (a management node)](/doc/mcollective/client.html)


