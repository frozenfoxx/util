#!/bin/sh

#################################################################
# Name:		disksuite-setup-1.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:		11/15/2008
# Description:	This is part one of three for building Solaris
#		Volume Manager/Disksuite software RAID groups
#		on Solaris.
#################################################################

# VARIABLES
DISK1=c1t0d0
DISK2=c1t1d0
DISK3=c1t2d0
DISK4=c1t3d0

echo "Clone the primary disk's partition table to secondary disks..."
prtvtoc /dev/rdsk/"$DISK1"s2 > /tmp/disk0
fmthard -s /tmp/disk0 /dev/rdsk/"$DISK2"s2
fmthard -s /tmp/disk0 /dev/rdsk/"$DISK3"s2
fmthard -s /tmp/disk0 /dev/rdsk/"$DISK4"s2

echo "\nThe new partition table for all secondary disks is as follows:"
cat /tmp/disk0

echo "\nAdding swap slice from secondary disk to primary swap..."
swap -a /dev/dsk/"$DISK2"s1
swap -a /dev/dsk/"$DISK3"s1
swap -a /dev/dsk/"$DISK4"s1

echo "\nNew swap locations are as follows:"
swap -l

echo "\nCreating meta databases on all disks..."
metadb -a -f /dev/dsk/"$DISK1"s7
metadb -a -f /dev/dsk/"$DISK2"s7
metadb -a -f /dev/dsk/"$DISK3"s7
metadb -a -f /dev/dsk/"$DISK4"s7
metadb

echo "\nCreating the root meta devices..."
metainit -f d10 1 1 "$DISK1"s0
metainit -f d20 1 1 "$DISK2"s0
metainit -f d30 1 1 "$DISK3"s0
metainit -f d40 1 1 "$DISK4"s0
metainit d0 -m d10

# Establish new root for the metadevice
metaroot d0

# Create more devices as desired.  The following are common examples.
# metainit -f d13 1 1 "$DISK1"s3
# metainit -f d23 1 1 "$DISK2"s3
# metainit -f d33 1 1 "$DISK3"s3
# metainit -f d43 1 1 "$DISK4"s3
# metainit d3 -m d13

# metainit -f d16 1 1 "$DISK1"s6
# metainit -f d26 1 1 "$DISK2"s6
# metainit -f d36 1 1 "$DISK3"s6
# metainit -f d46 1 1 "$DISK4"s6
# metainit d6 -m d16

# Make secondary disk root partition bootable in the event of failure
echo "\n Installing boot block onto first secondary disk..."
installboot /usr/platform/`uname -i`/lib/fs/ufs/bootblk /dev/rdsk/"$DISK2"s0

#Cleanup filesystem before reboot.
lockfs -fa

echo "\nConfirm root mount partition has been set correctly in vfstab. Also add swap and any other partitions to be mirrored."
echo "Example entry:"
echo "/dev/md/dsk/d0	/dev/md/rdsk/d0	/	ufs	1	no	-"
echo "/dev/md/dsk/d3	/dev/md/rdsk/d3	/var	ufs	1	no	-"
echo "/dev/md/dsk/d6	/dev/md/rdsk/d6	/usr	ufs	1	no	-\n"

echo "From the boot prom, change the boot-device to include both primary and secondary disks.  This will allow the system to boot successfully from the secondary disk in case the primary disk fails."
echo "Example:"
echo "setenv boot-device disk0:a disk1:a net"
echo "################################################################\n"

echo "Now reboot the server and then run disksuite-setup-2 to continue setup."
