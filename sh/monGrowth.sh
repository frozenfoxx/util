#!/bin/sh
################################################################################
## Name:		monGroth.sh
## Author:		FOXX (frozenfoxx@github.com)
## Date:		05/13/2009
## Description:		Quick script for monitoring growth of a partition. 
################################################################################

## awk version
##For Solaris
AWK=/usr/xpg4/bin/awk
##For others
#AWK=/usr/bin/nawk

## Variables
SEARCHTEXT=$1
OUTPUTFILE=$2
 
case "$SEARCHTEXT" in
'')
        echo "Usage:  monGrowth.sh <text to monitor in df -h> <tracking file>"
        echo ""
        ;;
*)
	## Grab interesting lines with grep from file system mountpoints,
	##  and print to a CSV file the date, the mount point, used space, and remain. space.
        (df -h |grep "$SEARCHTEXT") | $AWK -v datevar="`date`" '{print datevar "," $6 "," $3 "," $4 }' >> $OUTPUTFILE
        ;;
esac
exit 0
