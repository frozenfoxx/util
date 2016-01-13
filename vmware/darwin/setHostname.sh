#!/usr/bin/env bash
HOSTNAME=$(/Library/Application\ Support/VMware\ Tools/vmware-tools-daemon --cmd "info-get guestinfo.hostname")
hostname $HOSTNAME
scutil --set ComputerName $HOSTNAME
scutil --set LocalHostName $HOSTNAME
scutil --set HostName $HOSTNAME
dscacheutil -flushcache
