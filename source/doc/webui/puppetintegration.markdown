---
layout: page
title: "Integration with Puppet"
comments: true
sharing: true
footer: true
sidebar: false 
---

## The goal

Be able to assign Puppet modules to nodes from the Kermit WebUI interface.

And more to come.


## Prerequisites

You need a working Puppet installation (see [Puppet Master](doc/puppet/install.html)).

We use Hiera to store data values outside of the Puppet manifests. 

You have to provide Hiera on the Puppet master and on the Puppet clients.

Because Hiera is installed by default with Puppet v. 3, we strongly encourage
you to upgrade to v. 3.

Puppet v.3 requires ruby 1.8.7.

The [Puppet Labs rpm repository](http://yum.puppetlabs.com/) provides Puppet 3
for RHEL/Centos 5 and 6, and ruby 1.8.7 for RHEL/Centos 5.

The [Kermit repository](/doc/using_the_repo.html) provides in addition Puppet 3
and ruby 1.8.7 for RHEL/Centos 4. 

If you're still using Puppet v. 2, check
[Assign Modules to Nodes in Puppet With Hiera - How To](/blog/2012/07/01/puppet-hiera/)
for hints on how to install and use hiera with Puppet v. 2.

We chose redis (a key-value store) as the database backend for hiera because it
is simple and easy for what we need (simple mappings).

So install `redis` on the Puppet master.

## Configuration of the Puppet master  

Create or edit `/etc/puppet/hiera.yaml`

Here are some basic settings.

{% codeblock lang:yaml %}
---
:backends:
    - redis

:logger: console

:hierarchy:
    - common
    - %{fqdn}
    - %{hostname}

:redis:
    :password: nil
{% endcodeblock %}

You can add other levels in the hierarchy.

Examples :

* `%{operatingsystem}`
* `%{environment}`

You can set various options for redis. Check the [hiera-redis readme](https://github.com/reliantsecurity/hiera-redis#readme).


## Modify the puppet site manifest

Set :

{% codeblock lang:ruby %}
node default {
    hiera_include('classes','')
    # (...)
}

{% endcodeblock %}

And restart the Puppet master service.

## Test with a node

Let's say you have a test node named 'xyz' and a harmless Puppet module named 'test' (you can use [this test module](https://github.com/lofic/puppet-lofic/tree/master/modules/test)).

Assign the Puppet module to the node with :

{% codeblock lang:sh %}
echo 'sadd xyz:classes test' | redis-cli
echo 'smembers xyz:classes'  | redis-cli
{% endcodeblock %}


Force a refresh of the configuration on the Puppet node with :

{% codeblock lang:sh %}
puppet agent --test
{% endcodeblock %}
 
Verify that the module is applied on the Puppet node :

{% codeblock lang:sh %}
grep 'test' /var/lib/puppet/classes.txt
{% endcodeblock %}

Don't go further until this is working.

## Configure the Kermit Web UI

The Kermit Web UI will set some information in redis.

The Puppet master will use it.

In `/etc/kermit/kermit-webui.cfg`, set (adjust to your needs) :

{% codeblock lang:ini %}
[hiera]
redis_server=myredishost
redis_port=6379
redis_database=0
redis_password=

[puppet]
puppetmaster_hostname=mypmhost
{% endcodeblock %}

Then restart the Web UI :

{% codeblock lang:sh %}
/sbin/service httpd restart
{% endcodeblock %}

## Mapping classes from the Kermit Web UI

<div class="note" markdown='1'>
Firefox users : if you can't display the videos, try the direct link with one of these firefox plugins: Gstreamer/VLC/Divx web player/Windows media player.
</div>

{% video http://www.kermit.fr/video/Kermit-Edit_Puppet_Classes_with_Hiera_backend.mp4 1280 720 http://www.kermit.fr/video/Kermit-Edit_Puppet_Classes_with_Hiera_backend.jpg %}

[Direct link](http://www.kermit.fr/video/Kermit-Edit_Puppet_Classes_with_Hiera_backend.mp4)


## Verify 

Verify that your mappings are applied on the target Puppet nodes :

{% codeblock lang:sh %}
cat /var/lib/puppet/classes.txt
{% endcodeblock %}

Check that the mappings are written in redis :

{% codeblock lang:sh %}
$ redis-cli
redis > keys *
redis > smembers yournode:classes 
{% endcodeblock %}

Note that you can also set the default classes for all nodes with redis :

{% codeblock lang:sh %}
$ redis-cli
redis > sadd sadd common:classes a_module
redis > sadd sadd common:classes other_module
redis > smembers  common:classes 
{% endcodeblock %}

This will be soon available from the Kermit WebUI.

