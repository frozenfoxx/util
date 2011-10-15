#!/usr/bin/bash
###########################################################
# Name:		restoreDB.sh
# Author:	FOXX (frozenfoxx@github.com)
# Date:		09/19/2011
# Description:	this script will be able to restore a
#		database dump to a remote system, typically
#		via cron job.
# Related:	*restoreDB.sh       (backup host)
#		recreateRemoteDB.sh (restore host)
#		recreateDB.sh       (restore host)
# Dependencies:	Zmanda Recovery Manager
###########################################################

# GLOBAL VARIABLES
ADMUSER=admin
REMOTEDIR=/export/home/admin
SSH=/usr/bin/ssh

RESTORE=/usr/bin/mysql-zrm-restore
RESTOREUSER=restore
RESTOREPASSWORD=restorepass

PRODB="proddb"
DEVDB="devdb1 devdb2"

# This grabs only the latest full dataset at 2200
PRODDATASET=`ls /backups/proddb | grep '^[0-9]\{8\}22[0-9]\{4\}' | tail -1`
DEVDATASET=`ls /backups/devdb | grep '^[0-9]\{8\}22[0-9]\{4\}' | tail -1`

# Grab command-line argument
case "$1" in
'')
        echo "No environment specified."
        echo "Usage:  restoreDB.sh -[flash/dev/stage]"
        exit 1
        ;;

'-flash')
        ## Flash instance
	TARGET=flashhost.somedomain.net
	PORT=3306

	# Drop and create database remotely as admin user via sudo
	$SSH $ADMUSER@$TARGET $REMOTEDIR/recreateRemoteDB.sh flash
	;;

'-dev')
        ## Development instance
	TARGET=devhost.somedomain.net
	PORT=4406

	# Drop and create database remotely as admin user via sudo
	$SSH $ADMUSER@$TARGET $REMOTEDIR/recreateRemoteDB.sh dev
	;;

'-stage')
        ## Staging instance
	TARGET=stagehost.somedomain.net
	PORT=3306

	# Drop and create database remotely as admin user via sudo
	$SSH $ADMUSER@$TARGET $REMOTEDIR/recreateRemoteDB.sh stage
        ;;

*)
	# Unrcognized option
        echo "Unrecognized option."
        echo "Usage:  restoreDB.sh -[flash/dev/stage]"
        exit 1
        ;;
esac

# Restore the databases to the new empty DB
# cybertip database
for i in $PRODB ; do
  $RESTORE --user $RESTOREUSER --host $TARGET --port $PORT --password $RESTOREPASSWORD --backup-set proddb --source-directory /backups/proddb/$PRODDATASET/ --verbose --databases $i
done

# ecu_ta_db, leacontacts databases
for i in $DEVDB ; do
  $RESTORE --user $RESTOREUSER --host $TARGET --port $PORT --password $RESTOREPASSWORD --backup-set devdb --source-directory /backups/devdb/$DEVDATASET/ --verbose --databases $i
done

# Restoration is finished
echo ""
echo "Restore completed."

exit 0
