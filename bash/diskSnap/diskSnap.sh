#!/usr/bin/bash
#################################################################
# Name:		diskSnap.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:		10/07/2011
# Description:	this script controls ZFS snapshots and restores,
#		intended to be run out of cron.
# Related:      flashmysql/flashmysql.sh        (backup node)
#               controldb.sh                    (db host)
#               snapMySQL.sh                    (target node)
#               *diskSnap/diskSnap.sh           (target node)
#################################################################
# VARIABLES
ZFS=/usr/sbin/zfs
DATE=`date +%m%d%Y`

# Grab command-line argument
case "$1" in
  '')
    echo "No operations specified."
    echo "Usage:  diskSnap.sh [snap|restore] [disk path to snapshot]"
    exit 1
    ;;
  'snap')
    TARGET=$2
    echo "----------------------------"
    echo "diskSnap for ZFS initialized"
    echo "----------------------------"
    echo "Mode:         snapshot"
    echo "Target path:  $TARGET"
    echo "$ZFS snapshot $TARGET@$DATE"
    $ZFS snapshot $TARGET@$DATE
    echo "Backup complete."
    exit 0
    ;;
  'restore')
    echo "----------------------------"
    echo "diskSnap for ZFS initialized"
    echo "----------------------------"
    TARGET=$2
    echo "Mode:         restore"
    echo "Target path:  $TARGET"
    
    # Get the latest snapshot for the TARGET
    LATEST=`$ZFS list | grep $TARGET@ | awk '{print $1}' | sort -r | head -1`

    # Perform the restore
    echo "$ZFS rollback $LATEST"
    $ZFS rollback $LATEST
    echo "Restore complete."
    exit 0
    ;;
  *)
    echo "Unrecognized operation."
    echo "Usage:  diskSnap.sh [snap|restore] [disk path to snapshot]"
    exit 1
    ;;
esac
