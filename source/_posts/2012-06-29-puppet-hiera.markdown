---
layout: post
title: "Assign modules to nodes in Puppet with Hiera - How to"
date: 2012-07-01 02:15
post.author: Louis Coilliot 
author: Louis Coilliot
comments: true
sidebar: false
categories: [Puppet, Hiera]
---

## The goal

Be able to assign modules to nodes in Puppet with an external source of information.

This will allow to programmatically assign puppet modules to nodes and parameters to puppet modules.

And ease the development of frontends like a web interface for this task.

There are several approaches for this like External node classifiers and Hiera.

I chose Hiera, which is a datastore, with a redis database backend which is easy to query and update.


## References

This is a digest and how-to of these highly recommended readings :

[The problem with separating data from puppet code](http://puppetlabs.com/blog/the-problem-with-separating-data-from-puppet-code/)

[Hiera - Puppetlabs - Github](https://github.com/puppetlabs/hiera)

[First look installing and using Hiera - Puppetlabs](http://puppetlabs.com/blog/first-look-installing-and-using-hiera/)

[Hiera-redis - Reliantsecurity - Github](https://github.com/reliantsecurity/hiera-redis)


## Install Hiera

On the puppet master.

Debian-like systems :

{% codeblock lang:sh %}
# Not yet in the repo :
# puprel=puppetlabs-release_1.0-3_all.deb
# wget http://apt.puppetlabs.com/$pkg -O /tmp/$puprel
# sudo dpkg -i /tmp/$puprel
# apt-get -y install hiera hiera-puppet

# Failback :
sudo gem install hiera
sudo gem install hiera-puppet
{% endcodeblock %}

Red Hat EL 6 :

{% codeblock lang:sh %}
rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-1.noarch.rpm
rpm -ivh http://yum.puppetlabs.com/el/6/devel/x86_64/puppetlabs-release-devel-6-1.noarch.rpm 
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/puppetlabs-devel.repo
yum --enablerepo=puppetlabs-devel -y install hiera hiera-puppet
{% endcodeblock %}

Then :

{% codeblock lang:sh %}
modulepath=$(puppet master --configprint modulepath | awk -F: '{print $1}')
mkdir -p $modulepath
cd $modulepath
curl -L https://github.com/puppetlabs/hiera-puppet/tarball/master -o \
  'hiera-puppet.tar.gz' && mkdir hiera-puppet && tar -xzf hiera-puppet.tar.gz \
  -C hiera-puppet --strip-components 1 && rm hiera-puppet.tar.gz
{% endcodeblock %}

ATOW, the master branch was broken for my Puppet (2.7.11). I had to use a fix :

{% codeblock lang:sh %}
modulepath=$(puppet master --configprint modulepath | awk -F: '{print $1}')
mkdir -p $modulepath
cd /tmp
repo=https://github.com/kelseyhightower/hiera-puppet.git
branch=bug/1.0rc/15184_cannot_locate_the_hiera_config_file
git clone -b $branch $repo 
rsync -avu --exclude .git* /tmp/hiera-puppet/ $modulepath/hiera-puppet
{% endcodeblock %}

Many thanks to Volcane (R.I. pienaar) and Kelsey Hightower for the debugging.

It should be fine with the master branch in the version 1.0+

Now you need to synchronize the custom Hiera functions into the master.

Just restart the puppetmaster.

If needed, in addition, force the synchronisation with the following procedure.

On the master, with `pluginsync=true` in the `[main]` section of the `puppet.conf` : 


{% codeblock lang:sh %}
puppet agent --test
/etc/init.d/puppetmaster restart # if you don't use passenger
{% endcodeblock %}

## Configure hiera

Puppet expects a configuration file `/etc/puppet/hiera.yaml`

Here is a basic one :

{% codeblock hiera.yaml lang:yaml %}
:backends: 
    - yaml

:logger: console

:hierarchy: 
    - common

:yaml:
    :datadir: '/etc/puppet/hieradata'
{% endcodeblock %}

I set the hiera datadir in a subfolder of `/etc/puppet` to ease the backup of my puppet data (`/etc/puppet/{manifests,modules,hieradata}`).  

Create the "datastore" :

{% codeblock lang:sh %}
mkdir -p /etc/puppet/hieradata
{% endcodeblock %}

Create a basic database `/etc/puppet/hieradata/common.yaml` :


{% codeblock common.yaml lang:yaml %}
---
testmsg : Louis was here
{% endcodeblock %}

Test with :

{% codeblock lang:sh %}
hiera -c /etc/puppet/hiera.yaml testmsg
{% endcodeblock %}

## Test with a basic manifest

For example :

{% codeblock lang:ruby %}
class testhiera {
    $testmsg = hiera("testmsg")
    file { '/tmp/testhiera.txt':
        content => inline_template("<%= testmsg %>\n"),
    }
}
{% endcodeblock %}

## Use some parameters set in hiera

As an example let's use some parameters for a module dealing with jboss.

In `/etc/puppet/hieradata/common.yaml`

{% codeblock lang:yaml %}
jbossver: 6.1.0.Final
jboss::up: true
{% endcodeblock %}

You can use this in a manifest with :

{% codeblock lang:ruby %}
class jboss( $up = hiera('jboss::up', true) ) {
    
    $jbossver = hiera("jbossver")

    # (...)

    service{ 'jboss':
        require   => [ File['jboss_service'], Package['jbossas'], ],
        ensure  => $up? { true => running, 'true' => running, default => stopped },
        enable  => $up? { true => true,    'true' => true,    default => false   },
    }

}
{% endcodeblock %}

`hiera('jboss::up', true)` means that puppet should failback to true if the key is not found in hiera.

## Assign modules to nodes

We can assign classes to a single node, to a subset of nodes or to all nodes as default classes.

For example, in `hiera.yaml`, you can set a hierarchy :

{% codeblock lang:yaml %}
:hierarchy:
    - common             # all nodes
    - %{operatingsystem} # subset
    - %{hostname}        # single node
{% endcodeblock %}

You can use any standard or custom facter fact in your hierarchy.

With the hierarchy above, and a Red Hat puppet client named `infrmon01`, we could have three yaml files in the folder `hieradata` : 

* `common.yaml`
* `RedHat.yaml`
* `infrmon01.yaml`

In `common.yaml` we set the classes applied to all nodes :

{% codeblock common.yaml lang:yaml %}
---
classes: ['core', 'mcollective', 'ntp', 'profile', 'ssh', 'vim']
{% endcodeblock %}

In `RedHat.yaml`, we set the classes applied to all Red Hat systems :
{% codeblock RedHat.yaml lang:yaml %}
---
classes: ['yum']
{% endcodeblock %}

In `infrmon01.yaml`, we set the classes applied to this specific host :
{% codeblock infrmon01.yaml lang:yaml %}
---
classes: ['rabbitmq', 'redis', 'sensu::server']
{% endcodeblock %}

Note : you need to respect a whitespace after the comma.

And in your site manifest :

{% codeblock site.pp lang:ruby %}
node default {
    hiera_include('classes','')
}
{% endcodeblock %}


Again, `''` is the failback.

`hiera_include` will merge all the arrays down the hierarchy giving you the combined classes list for each node.

## Switch the backend to redis

{% codeblock lang:sh %}
gem install redis
gem install hiera-redis
{% endcodeblock %}

In `/etc/puppet/hiera.yaml`, add or switch to the new backend :

{% codeblock hiera.yaml lang:yaml %}
:backends: 
    - redis

:redis:
    :password: nil
{% endcodeblock %}

Note : in the version of hiera-redis that I use, I need at least a parameter in `:redis` to avoid a bug `undefined method 'has_key?'`

## Insert your data into redis.

For example, to set :

{% codeblock lang:yaml %}
testmsg : Louis was here
jbossver: 6.1.0.Final
jboss::up: true
{% endcodeblock %}

you can use the redis CLI :

{% codeblock redis-cli lang:sh %}
redis-cli<<'EOF'
set common:jbossver 6.1.0.Final
set common:testmsg "Louis was here"
set common:jboss::up true
keys *
EOF
{% endcodeblock %}

Note : `true` in the yaml file was used as a boolean in puppet, but it is a string with redis. This is the reason of :

{% codeblock lang:ruby %}
        ensure  => $up? { true => running, 'true' => running, default => stopped },
{% endcodeblock %}

in the manifest above.

The mapping between puppet classes and nodes is done like this :

{% codeblock redis-cli lang:sh%}
# Default classes for all nodes
redis-cli<<'EOF'
sadd common:classes core
sadd common:classes mcollective
sadd common:classes ntp
sadd common:classes profile
sadd common:classes ssh
sadd common:classes vim
smembers common:classes
EOF

# Custom classes for the hostname infrmon01
redis-cli<<'EOF'
sadd infrmon01:classes rabbitmq
sadd infrmon01:classes redis 
sadd infrmon01:classes sensu::server
smembers  infrmon01:classes 
EOF
{% endcodeblock %}
 

## WebUI

This is what it looks like in the Kermit Web UI (development version, so far) : 

{% video http://www.kermit.fr/video/Kermit-Edit_Puppet_Classes_with_Hiera_backend.mp4 1280 720 http://www.kermit.fr/video/Kermit-Edit_Puppet_Classes_with_Hiera_backend.jpg %}

<div class="note" markdown='1'>
Firefox users : if you can't display the video, try <a href='http://www.kermit.fr/video/Kermit-Edit_Puppet_Classes_with_Hiera_backend.mp4'>this direct link</a> with one of these firefox plugins: Gstreamer/VLC/Divx web player/Windows media player.
</div>
