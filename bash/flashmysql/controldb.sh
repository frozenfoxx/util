#!/usr/bin/bash
#############################################################
# Name:         controldb.sh
# Date:         10/10/2011
# Author:	FOXX (frozenfoxx@github.com)
# Description:  this script enables various remote commands 
#		for the database.  This is required in setups
#		where there is a privileged admin user and
#		no remote root login.
# Related:	flashmysql/flashmysql.sh	(backup node)
#		*controldb.sh			(db host)
#		snapMySQL.sh			(target node)
#		diskSnap/diskSnap.sh		(target node)
# Dependencies:	sudo
#		MySQL
#############################################################
# VARIABLES
SUDO=/usr/local/bin/sudo
MYSQLADM=/opt/mysql/bin/mysqladmin
STARTSCRIPT=/etc/init.d/mysql.server
DBSOCK=/tmp/db.sock
DBPASS="rootpass"

case "$1" in
'')
        # No option
        echo "No environment specified."
        echo "Usage:  controldb.sh [stop|start]"
        exit 1
        ;;
'stop')
        # Stop the database
	$MYSQLADM shutdown -S $DBSOCK -u root --password=$DBPASS
        exit 0
        ;;
'start')
        # Start the database
	$SUDO $STARTSCRIPT start
        exit 0
        ;;
*)
        # Unrcognized option
        echo "Unrecognized option."
        echo "Usage:  controldb.sh [stop|start]"
        exit 1
        ;;
esac
