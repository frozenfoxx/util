#!/bin/sh

#################################################################
# Name:		disksuite-setup-2.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:		11/08/2010
# Description:	This is part two of three for building Solaris
#		Volume Manager/Disksuite software RAID groups
#		on Solaris.
#################################################################

# Attach sub-devices to the metadevices

echo "Attaching subdevices to metadevice d0..."
metattach d0 d20
metattach d0 d30
metattach d0 d40

# echo "Attaching subdevices to metadevice d3..."
# metattach d3 d23
# metattach d3 d33
# metattach d3 d43

# echo "Attaching subdevices to metadevice d6..."
# metattach d6 d26
# metattach d6 d36
# metattach d6 d46

echo "\nAttachment completed.  Run disksuite-setup-3.sh to check on status of disk sync."
