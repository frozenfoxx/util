#!/bin/sh

#######################################################################
## Name:		dir-copy.sh
## Author:		FOXX (frozenfoxx@github.com)
## Date:		08/17/2009
## Description:		this script will copy a tree of directories
##			and notify a user via e-mail if there is a new
##			one created.  It is most useful for regularly
##			expanded directories.
## Requirements:	rsync
#######################################################################

## VARIABLES
# Known directories
DIRS="exampledir50 exampledir100 exampledir150 exampledir200 exampledir250 exampledir300 exampledir350 exampledir400 exampledir450 exampledir500 exampledir550"

# Target log file for monitoring
LOGFILE=/home/bob/logs/copy.log_`date '+%H%M%m%d%y'`

# Default mail program in the system
MAILER=/bin/mailx

## Begin a test for the number of directories
# Initialize the counter for number of directories
DCOUNT=0

# Check number of elements in DIRS array
for DIRS in $DIRS; do
        DCOUNT=`expr $DCOUNT + 1`
done

## Uncomment the following line for troubleshooting
#echo "Dirs Count = $DCOUNT"

# Get the number of directories in /var/edirs
CURRENTCOUNT=`ls /var/edirs | wc -l`

## Uncomment the following line for troubleshooting
#echo "Current Count = $CURRENTCOUNT"

## Begin the logging and transfer

# Compare to see if new directories have been created
if [ $CURRENTCOUNT -gt $DCOUNT ]; then
        # The directory count has CHANGED!
	date >> $LOGFILE
	echo "SYNCING ENTIRE DIRECTORY" >> $LOGFILE
        # Run full rsync
        rsync --verbose --progress --stats --compress --rsh=/usr/bin/ssh --rsync-path=/usr/bin/rsync --recursive --times --owner --group --perms --links --delete /var/edirs/ bob@system2:/var/edirs/ >> $LOGFILE
        # Send a notice to the user to update the list of known directories
        echo "Please update system1:/home/bob/ct_copy.sh" | $MAILER -s "New directories created in /var/edirs!" admin@somedomain.net
	echo "SYNC OF $DIRS COMPLETE" >> $LOGFILE
	date >> $LOGFILE
	echo ""
	echo ""
else
        ## The directory count does not appear to have changed, all is good
	for DIRS in $DIRS; do
		date >> $LOGFILE
		echo "SYNCING $DIRS DIRECTORY" >> $LOGFILE
        	rsync --verbose --progress --stats --compress --rsh=/usr/bin/ssh --rsync-path=/usr/bin/rsync --recursive --times --owner --group --perms --links --delete /var/edirs/$DIRS/ bob@system2:/var/edirs/$DIRS >> $LOGFILE
		echo "SYNC OF $DIRS COMPLETE" >> $LOGFILE
		date >> $LOGFILE
		echo ""
		echo ""
	done
fi

echo "Removing log files older than 7 days" >> $LOGFILE
find /home/bob/logs -mtime +7 -type f -name "copy.log*" \! -exec /bin/rm {} \;

