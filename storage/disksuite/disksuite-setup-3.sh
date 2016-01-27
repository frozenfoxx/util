#!/bin/sh

#################################################################
# Name:		disksuite-setup-3.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:		11/15/2008
# Description:	This is part three of three for building Solaris
#		Volume Manager/Disksuite software RAID groups
#		on Solaris.
#################################################################

# This is a simple check on the status of all disks in resync.

echo "Beginning watch of resync.  Break with <Ctrl> + C at any time."

while true
do
  metastat |grep "Resync in progress"
  echo ""
  sleep 10
done
