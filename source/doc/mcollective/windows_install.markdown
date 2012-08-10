---
layout: page
title: "Windows node"
comments: true
sharing: true
footer: true
sidebar: false 
---

## Prerequisites

Install Ruby 1.8.7 by downloading the `.exe` file from  [rubyinstaller.org](http://rubyinstaller.org/)

During the installation, select 'Add ruby executables to your path' and
 'Associate .rb files with this Ruby installation'

## Install with the binary installer

Download from :
[kermit.fr/repo/windows/bin/mcollective_Setup.exe](http://www.kermit.fr/repo/windows/bin/mcollective_Setup.exe)

## Configure

Configure `server.cfg` as usual.

## Fallback manual installation

### Installation

Open a ruby console (a link was created during the installation in the Start Menu) and install some required gems.

```bash
gem install stomp
gem install win32-process
gem install win32-service
gem install sys-admin
gem install windows-api
```

Download the source code from the mcollective website:

[mcollective-2.0.0.tgz](http://puppetlabs.com/downloads/mcollective/mcollective-2.0.0.tgz)

Extract the package on your system node, `c:\mcollective` in our example

Copy all the files from `c:\mcollective\ext\windows` to `c:\mcollective`

```bat
cp c:\mcollective\ext\windows\*.* c:\mcollective
```

### Configuration

#### Client

```bat
cp c:\mcollective\etc\client.cfg.dist c:\mcollective\etc\client.cfg
cp c:\mcollective\etc\facts.yaml.dist c:\mcollective\etc\facts.yaml
```

Edit the `client.cfg` to set mcollective paths

```cfg
libdir = c:\mcollective\plugins
plugin.yaml = c:\mcollective\etc\facts.yaml
```

#### Server

```bat
cp c:\mcollective\etc\server.cfg.dist c:\mcollective\etc\server.cfg
```

Edit the `server.cfg` to set mcollective paths

```cfg
libdir = c:\mcollective\plugins
logfile = c:\mcollective\mcollective.log
plugin.yaml = c:\mcollective\etc\facts.yaml
daemonize = 1
```

### Register mcollective as a windows service

```bat
cd c:\mcollective\bin
register_service.bat
```

Then set the service to start automatically at boot time.

Cf `bin\environment.bat` : 

```bat
REM SET MC_STARTTYPE=manual
SET MC_STARTTYPE=auto
```

## Troubleshooting

You can run the service manually.

Get the command line with :

My Computer -> Services -> Service = 'The Marionette Collective' -> Properties 
-> Path to executable

And set the `loglevel` to `debug` in `server.cfg`


