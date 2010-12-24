#!/bin/sh

################################################################################
## Name:  		check-df.sh
## Author:		FOXX (frozenfoxx@github.com)
## Date:		04/09/2009
## Description:		Takes in an expression for a part of "df -h" to monitor.
################################################################################

case "$1" in
'')
	echo "Usage:  check-df.sh <text to monitor in df -h>"
	echo ""
	;;
*)	
	while true
	do
  		df -h |grep "$1"
  		sleep 10
	done
	;;
esac
exit 0
