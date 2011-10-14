#!/usr/bin/bash
#################################################################
# Name:         snapMySQL.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:         10/10/2011
# Description:  this script controls ZFS snapshots and restores,
#               intended to be run out of cron.  Typically from
#		a special, unprivileged "admin" user given
#		sudo rights to run diskSnap.sh.
# Related:      flashmysql/flashmysql.sh        (backup node)
#               controldb.sh                    (db host)
#		*snapMySQL.sh			(target node)
#               diskSnap/diskSnap.sh            (target node)
# Dependencies:	sudo
#		diskSnap
#		ZFS
#		Solaris Zone with MySQL
#		MySQL shut down
#################################################################
# VARIABLES
MYSQLZONE="rpool/zones_pool/zoneHost-dbZone"
DISKSNAP=/export/home/root/diskSnap/diskSnap.sh
SUDO=/usr/local/bin/sudo

# Grab command-line argument
case "$1" in
  '')
    echo "No operations specified."
    echo "Usage:  snapMySQL.sh [snap|restore]"
    exit 1
    ;;
  'snap')
    $SUDO $DISKSNAP snap $MYSQLZONE
    exit 0
    ;;
  'restore')
    $SUDO $DISKSNAP restore $MYSQLZONE
    exit 0
    ;;
  *)
    echo "Unrecognized operation."
    echo "Usage:  snapMySQL.sh [snap|restore]"
    exit 1
    ;;
esac
