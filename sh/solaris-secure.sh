#!/bin/sh

################################################################################
## Name:  		solaris-secure.sh
## Author:		FOXX (frozenfoxx@github.com)
## Date:		06/10/2009
## Description:		This script will shut down unnecessary services and
##			otherwise tune Solaris to safer default settings.
################################################################################

# Insecure Services
/usr/sbin/svcadm disable svc:/network/telnet:default
/usr/sbin/svcadm disable svc:/network/rpc/rstat:default
/usr/sbin/svcadm disable svc:/network/ftp:default 
/usr/sbin/svcadm disable svc:/network/smtp:sendmail
/usr/sbin/svcadm disable svc:/network/rpc/cde-ttdbserver:tcp
/usr/sbin/svcadm disable svc:/network/nfs/rquota:default
/usr/sbin/svcadm disable svc:/application/management/dmi:default
/usr/sbin/svcadm disable svc:/application/management/snmpdx:default
#/usr/sbin/svcadm disable svc:/application/management/sma:default
/usr/sbin/svcadm disable svc:/system/power:default
/usr/sbin/svcadm disable svc:/system/webconsole:console
/usr/sbin/svcadm disable svc:/network/stlisten:default
/usr/sbin/svcadm disable svc:/application/stosreg:default
/usr/sbin/svcadm disable svc:/network/stdiscover:default


# Services found by Nessus scans
echo "DTlogin.request:	0" >> /usr/dt/config/Xconfig

/usr/sbin/svcadm disable svc:/network/rpc/rusers:default

/usr/sbin/svcadm disable svc:/network/nfs/nlockmgr:default

/usr/sbin/svcadm disable svc:/network/finger:default

/usr/sbin/svcadm disable svc:/network/login:rlogin

/usr/sbin/svcadm disable svc:/network/shell:default
