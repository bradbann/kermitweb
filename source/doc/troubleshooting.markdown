---
layout: page
title: "KermIT problems troubleshooting"
comments: true
sharing: true
footer: true
sidebar: false 
---

## It does not work, but where ?

From the webui to the remote action on a node, KermIT uses a chain of different components. 

So, it will help us if you can spot precisely where your problem is before asking for help and/or opening a ticket.

For example, is the problem in the Webui, before a call to the MCollective subsystem ?  

Is it when the WebUI reads the response ?

Is it in-between ?

To debug a problem there are differents places where you have to look in the right order.

## KermIT WebUI Log

`/var/log/kermit/kermit-webui.log`

This is where all the information and errors for the webui are logged. 

The verbosity depends on your log level (INFO by default).

This is the right place to start looking for an error.

You can change the verbosity in `/etc/kermit/kermit-webui.cfg`

{% codeblock lang=ini%}
[webui_logs]
main.file=/var/log/kermit/kermit-webui.log
main.level=INFO
calls.file=/var/log/kermit/kermit-mcollective-calls.log
calls.level=DEBUG
{% endcodeblock %}


Valid log levels = DEBUG, INFO, WARN, ERROR


## Celery Log

Celery could have one or more logs file, it depends of the configuration of the celery workers.

A worker is a thread that gets a call from Kermit to MCollective and runs it.

So, for example, if you have a stucked progress bar after launching an operation, you should check the celery logs.

Because it could mean that KermIT cannot contact celery to get tasks results.

The configuration file is `/etc/sysconfig/celeryd`

If you have more than one worker, check every worker log to find the one that ran (or is still running) your operation.

For example, with a configuration that sets 3 workers, you'll have :

{% codeblock %}
/var/log/celeryw1.log
/var/log/celeryw2.log
/var/log/celeryw3.log
{% endcodeblock %}


## REST Server

To contact the MCollective backend, KermIT uses a REST server. Because it permits the low coupling, and because it is language agnostic. 

So it's important to check this server is active and responding.

Sometimes, especially after an update of Kermit or Mcollective, restart the REST service, standalone or via Apache and Passenger (better for robustness and scalability).

There is a full testing and troubleshooting procedure in the documentation of the REST server.

Be sure you use the production mode with Apache and Passenger.

[REST server installation and troubleshooting](/doc/restmco/install.html)

Try manually a few URLs locally on the REST server, like :

{% codeblock lang:sh %}
cd /tmp
wget http://localhost # you should get a page with 'Hello Sinatra'
wget http://localhost/mcollective/no-filter/rpcutil/ping/
wget http://localhost/mcollective/no-filter/package/status/package=bash
{% endcodeblock %}



## MCollective Log

If you get a wrong or empty response (seen in your celery log) from MCollective, you should check the mcollective logs on the target machine (the node where you try to execute an action).

Locally on the target node : `/var/log/mcollective.log`

Try to launch the MCollective action and agent without the Kermit framework, in a console on a MCollective client.


Example :

{% codeblock lang:sh %}
mco help rpc
mco rpc package status package=bash
{% endcodeblock %}


Get the agent, action and parameters in the `kermit-mcollective-calls.log`

## Remote scheduler logs

For some asynchronous tasks, KermIT calls a MCollective scheduler application.

The scheduler runs locally on the target node. It manages the scheduled
MCollective tasks locally. KermIT uses a task ID to get the status and result
asynchronously.

For those tasks, check ON THE TARGET NODE :

* that the `schedulerd` service is running 
* the calls (`*.desc`) and results (`*.exception`, `.err`, `*.out`) in `/tmp/sched` 

You can also run the service with an output at the console for debugging :

{% codeblock %}
/usr/local/bin/schedulerd run
{% endcodeblock %}


Try to launch the MCollective action and agent without the Kermit framework, in
a console on a MCollective client.

Example :

{% codeblock lang:sh %}
mco schedule rpcutil ping --with-id=/el6/
mco schedule -o -k <jobid> --with-id=/el6/
{% endcodeblock %}


## Summary of services

On the NOC, you should have these services running :
* httpd (WebUI and REST server with Passenger)
* kermit-inventory (inventory queue consumer daemon )
* kermit-log (log queue consumer daemon)
* celeryev (task monitor)
* celerybeat (task scheduler)
* celeryd (task manager)
* redis (task broker)

Check the [WebUI admin guide](/doc/webui/userguide.html) for more details on how
to monitor the status of the services and how to restart the services in the
right order.

On the managed nodes, you should have these services running :

* mcollective
* puppet (if you use puppet for deployments and configuration management) 
* schedulerd (if you use long tasks managed asynchronously)
 

## And then ?

If you still can't spot the problem or find the solution, then send us the trace
and logs for all the checks above.

* `kermit-webui.log`
* `/var/log/celeryw*.log`
* `/var/log/kermit/kermit-mcollective-calls.log`
* the result of the direct REST server calls
* `/var/log/mcollective.log` on the remote target node 
* `/tmp/sched/*`

