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

Be able to assign modules to nodes in Puppet with an external source of
information.

This will allow to programmatically assign puppet modules to nodes and
 parameters to puppet modules.

And ease the development of frontends like a web interface for this task.

There are several approaches for this like External node classifiers and Hiera.

I chose Hiera, which is a datastore, with a redis database backend which is easy
to query and update.


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

It should be fine with the master branch in the future version 1.0

Now you need to synchronize the custom Hiera functions into the master.

Just restart the puppetmaster.

If needed, in addition, force the synchronisation with the following procedure.

On the master, with `pluginsync=true` in the `[main]` section of the
`puppet.conf` : 


{% codeblock lang:sh %}
puppet agent --test
/etc/init.d/puppetmaster restart # if you don't use passenger
{% endcodeblock %}

## Configure hiera

Puppet expects a configuration file `/etc/puppet/hiera.yaml`

Here is a basic one :

{% codeblock lang:yaml %}
:backends: 
    - yaml

:logger: console

:hierarchy: 
    - common

:yaml:
    :datadir: '/etc/puppet/hieradata'
{% endcodeblock %}

I set the hiera datadir in a subfolder of `/etc/puppet` to ease the backup of my
puppet data (`/etc/puppet/{manifests,modules,hieradata}`).  

Create the "datastore" :

{% codeblock lang:sh %}
mkdir -p /etc/puppet/hieradata
{% endcodeblock %}

Create a basic database `/etc/puppet/hieradata/common.yaml` :


{% codeblock lang:yaml %}
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

`hiera('jboss::up', true)` means that puppet should failback to true if the 
 key is not found in hiera.

## Assign modules to nodes

For a puppet client named `infrmon01`, we could set in `common.yaml` :

{% codeblock lang:yaml %}
infrmon01: ['rabbitmq', 'redis', 'sensu::server']
{% endcodeblock %}

Note : you need to respect a whitespace after the comma.

And in your node declaration :

{% codeblock lang:ruby %}
node infrmon01 inherits default {
    hiera_include($hostname,'')
}
{% endcodeblock %}

Or even :


{% codeblock lang:ruby %}
node default {
    hiera_include('defaultclasses','')
    hiera_include($hostname,'')
}
{% endcodeblock %}


Again, `''` is the failback.

## Switch the backend to redis

{% codeblock lang:sh %}
gem install redis
gem install hiera-redis
{% endcodeblock %}

In `/etc/puppet/hiera.yaml`, add or switch to the new backend :

{% codeblock lang:yaml %}
:backends: 
    - redis

:redis:
    :password: nil
{% endcodeblock %}

Note : in the version of hiera-redis that I use, I need at least a parameter in
 `:redis` to avoid a bug `undefined method 'has_key?'`

Insert your data into redis.

For example, to set :

{% codeblock lang:yaml %}
testmsg : Louis was here
jbossver: 6.1.0.Final
jboss::up: true
infrmon01: ['rabbitmq', 'redis', 'sensu::server']
{% endcodeblock %}

you can use the redis CLI :

{% codeblock lang:sh %}
redis-cli<<'EOF'
set common:jbossver 6.1.0.Final
set common:testmsg "Louis was here"
set common:jboss::up true
sadd common:infrmon01 rabbitmq
sadd common:infrmon01 redis
sadd common:infrmon01 sensu::server
keys *
smembers common:infrmon01
EOF
{% endcodeblock %}

Note : `true` in the yaml file was used as a boolean in puppet, but it is a
 string with redis. This is the reason of :

{% codeblock lang:ruby %}
        ensure  => $up? { true => running, 'true' => running, default => stopped },
{% endcodeblock %}

in the manifest above.

## WebUI

The WebUI is left as an exercise for the reader (for now).

This is what it looks like in the Kermit Web UI (development version, so far) : (soon...)



