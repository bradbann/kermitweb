---
layout: page
title: "Automatic deployment"
comments: true
sharing: true
footer: true
sidebar: false 
---


Puppet resources and classes :

{% codeblock lang:sh %}
/etc/puppet/modules/yum/manifests/init.pp

/etc/puppet/modules/yum/files/kermit.repo

/etc/puppet/modules/mcollective/manifests/init.pp

/etc/puppet/modules/mcollective/files/client.cfg
/etc/puppet/modules/mcollective/files/server.cfg

# Advanced configuration with the ssl plugin :
/etc/puppet/modules/mcollective/files/noc-public.pem
/etc/puppet/modules/mcollective/files/server-public.pem
/etc/puppet/modules/mcollective/files/server-private.pem

{% endcodeblock %}

You can use the templates of
[https://github.com/kermitfr/puppetclasses](https://github.com/kermitfr/puppetclasses)

But you’ll have to set your own .pem keys and certificates.

Define somewhere in your puppet classes :

{% codeblock lang:ruby %}
$nocnode = 'your_noc_hostname'
{% endcodeblock %}


