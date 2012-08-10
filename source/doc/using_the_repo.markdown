---
layout: page
title: "Using the Kermit Repository"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Sources of the packages

We use packages from third part repositories: mainly EPEL, ELFF, Atomic, rabbitmq.org.

* [EPEL](http://fedoraproject.org/wiki/EPEL)

* [ELFF](http://download.elff.bravenet.com/) (ruby and ruby gems)

* [rabbitmq.org](http://www.rabbitmq.com/server.html) (rabbitmq)

* [people.fedoraproject.org - ~tmz](http://people.fedoraproject.org/~tmz/repo/puppet/) (puppet)

* [repos.fedorapeople.org - peter](http://repos.fedorapeople.org/repos/peter/erlang/) (erlang R14)

But not exclusively.

Those packages have been collected and are provided in a single repository :
* for convenience
* as the consistent set of packages used during our tests

They might be not up to date at the time of reading.

Some other packages (mcollective plugins, rabbitmq plugins, ...) are custom
builds, referred below as custom packages.

For el4, a lot a packages are custom builds.

For el5, many packages are custom builds.

For el6 (much more up to date) a few packages are custom builds. We rely on many packages of EPEL.

The repository with collected and custom packages is available here :
[Kermit repository](http://www.kermit.fr/repo/rpm/)

## Use the repository

Set the repository with : `http://www.kermit.fr/stuff/yum.repos.d/kermit.repo`

{% codeblock lang:sh %}
wget http://www.kermit.fr/stuff/yum.repos.d/kermit.repo \
     -O /etc/yum.repos.d/kermit.repo
{% endcodeblock %}

On el4 and el5 you do not need EPEL in addition to the kermit repository.

On el6 you MUST use the kermit repository in conjunction with EPEL.

If your systems don't have access to internet you should consider providing a
local yum mirror or a custom satellite channel.

## Import the GPG keys

Used to verify the signature of the packages.

You can get the keys at
[http://www.kermit.fr/stuff/gpg/](http://www.kermit.fr/stuff/gpg/)


{% codeblock lang:sh %}
rpm --import http://www.kermit.fr/stuff/gpg/RPM-GPG-KEY-lcoilliot
rpm -ivh http://www.kermit.fr/stuff/gpg/kermit-gpg_key_whs-1.0-1.noarch.rpm
rpm --import /etc/pki/rpm-gpg-kermit/RPM-GPG-KEY-*
{% endcodeblock %}

List the imported keys with :

{% codeblock lang:sh %}
rpm -q --queryformat "%{SUMMARY}\n" $(rpm -q gpg-pubkey)
{% endcodeblock %}

