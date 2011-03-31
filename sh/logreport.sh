#!/sbin/sh

################################################################################
## Name:  		logreport.sh
## Author:		FOXX (frozenfoxx@github.com)
## Date:		07/22/2009
## Description:		This script watches a logfile for a particular series
##			of keywords (user-defined in this file) and sends
##			an e-mail when they show up.  It is intended be
##			used in conjunction with cron for scheduling in
##			instances where you can be clobbered with e-mail.
################################################################################

CURRENTLOG=/home/root/logreport/CurrentLog.sh
DIFFLOG=/home/root/logreport/logreport.current
MAILER=/usr/bin/mailx
RECIPIENT=someadmin@somecompany.net
PHRASES='deadlock|Logging System quota has been exceeded|Aborting'
HOSTNAME=`hostname`

#Get current file to compare
$CURRENTLOG

## We test to see if there's actually anything to e-mail about
if [ `egrep -i -e "$PHRASES" $DIFFLOG | wc -l` -gt 0 ] ; then
  echo "Please check `hostname` now." | $MAILER -s "$HOSTNAME encountered $PHRASES!" $RECIPIENT
fi
