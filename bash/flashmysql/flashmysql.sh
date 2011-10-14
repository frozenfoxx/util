#!/usr/bin/bash
#################################################################
# Name:         flashmysql.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:         10/11/2011
# Description:  this script allows for "flashing" a MySQL DB.
#		It's the master that shuts down the MySQL DB on a
#		Solaris Zone, performs a file system-level snap-
#		shot, and starts it back up.  It also allows for
#		reverting, allowing for significantly faster
#		restoration.
# Related:      *flashmysql/flashmysql.sh       (backup node)
#               controldb.sh			(db host)
#		snapMySQL.sh			(target node)
#               diskSnap/diskSnap.sh		(target node)
# Dependencies:	sudo
#		diskSnap
#		ZFS
#		Solaris Zone
# Notes:	it is generally assumed that the Target Node is
#		a Solaris global zone, and the db host is a zone
#		hosting MySQL underneath of it.
#################################################################
# VARIABLES
ADMUSER=admin
ADMDIR=/export/home/admin
SSH=/usr/bin/ssh

# Grab command-line argument
case "$1" in
  '')
    echo "No operations specified."
    echo "Usage:  flashmysql.sh [snap|flash] [target node] [db host]"
    exit 1
    ;;

  'snap')
    TARGET=$2
    DBHOST=$3

    echo ""
    echo "/************ Stopping remote database on $DBHOST **************/"
    $SSH $ADMUSER@$DBHOST $ADMDIR/controldb.sh stop

    echo ""
    echo "/************ Beginning disk snapshot on $TARGET **************/"
    $SSH $ADMUSER@$TARGET $ADMDIR/snapMySQL.sh snap

    echo ""
    echo "/*********** Starting remote database on $DBHOST **************/"
    $SSH $ADMUSER@$DBHOST $ADMDIR/controldb.sh start
    exit 0
    ;;

  'flash')
    TARGET=$2
    DBHOST=$3

    echo ""
    echo "/************ Stopping remote database on $DBHOST **************/"
    $SSH $ADMUSER@$DBHOST $ADMDIR/controldb.sh stop

    echo ""
    echo "/*************** Beginning disk flash on $TARGET ****************/"
    $SSH $ADMUSER@$TARGET $ADMDIR/snapMySQL.sh restore

    echo ""
    echo "/*********** Starting remote database on $DBHOST **************/"
    $SSH $ADMUSER@$DBHOST $ADMDIR/controldb.sh start
    ;;

  *)
    echo "Unrecognized operation."
    echo "Usage:  flashmysql.sh [snap|flash] [target node] [db host]"
    exit 1
    ;;
esac
