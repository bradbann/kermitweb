---
layout: page
title: "Secure MCollective"
comments: true
sharing: true
footer: true
sidebar: false 
---


## The issue

A MCollective client is able to execute actions on all the managed nodes.

The default out of the box installation for MCollective uses a psk (pre-shared key) for identification of the nodes and callers.

Cf `/etc/mcollective/server.cfg` (0640) :

{% codeblock lang:ini %}
# Plugins
securityprovider = psk
plugin.psk = thekey
{% endcodeblock %}

It means that anyone having a root access to one of the nodes can install the mcollective-client package and use the psk to control all the other nodes.

That's not what you want in a big infrastructure where administrators have delimited perimeters according to specific environments.

Fortunately you can deal with this.

The MCollective SSL security plugin provides strong caller identification.

Optionally the AES + SSL plugin adds payload encryption, identification of servers and optional automatic key distribution.

You should familiarize yourself with these matters by reading :

[MCollective Security Overview](http://puppetlabs.com/mcollective/security-overview/)

[SSL security plugin](http://docs.puppetlabs.com/mcollective/reference/plugins/security_ssl.html)

[AES security plugin](http://docs.puppetlabs.com/mcollective/reference/plugins/security_aes.html)

Below we describe how to set the SSL security plugin (not the AES plugin).

## Set a key pair for the nodes

See [SSL security plugin](http://docs.puppetlabs.com/mcollective/reference/plugins/security_ssl.html),
Setup -> Nodes

We set a `server-public.pem` and `server-private.pem` key pair.

## Set a key pair for a client

Client = management client.

See [SSL security plugin](http://docs.puppetlabs.com/mcollective/reference/plugins/security_ssl.html),
Setup -> Users and Clients 

We set a `noc-public.pem` and `noc-private.pem` key pair.

<div class="important" markdown='1'>
DON'T deploy `noc-private.pem`
</div>

## Deploy the configuration and keys with puppet

Puppet resources and classes :

{% codeblock %}
/etc/puppet/manifests/classes/mcollective.pp
/etc/puppet/manifests/classes/yum.pp

/etc/puppet/modules/mcollective/files/client.cfg
/etc/puppet/modules/mcollective/files/server.cfg
/etc/puppet/modules/mcollective/files/noc-public.pem
/etc/puppet/modules/mcollective/files/server-public.pem
/etc/puppet/modules/mcollective/files/server-private.pem
/etc/puppet/modules/yum/files/kermit.repo
{% endcodeblock %}


You can use the templates from [https://github.com/thinkfr/puppetclasses](https://github.com/thinkfr/puppetclasses)

But you'll have to set your own `.pem` keys and certificates.

Define somewhere in your puppet classes :

{% codeblock lang:ini %}
$nocnode = 'your_noc_hostname'
{% endcodeblock %}

