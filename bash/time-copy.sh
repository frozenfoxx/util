#!/bin/bash

## Name:  time-copy.sh
## Author:  FOXX (frozenfoxx@github.com)
## Date:  01/24/2009
## Description:  this is a quick and simple script to test the time taken
##  to transfer a file.


#VARIABLES
FILESIZE='1024m'
TARGETSERVER='cris24.cybertip.org'

#Create file
echo "Creating the garbage.txt of $FILESIZE"
mkfile $FILESIZE garbage.txt

echo "Time started:  `date +%H:%M:%S`"              
scp garbage.txt tcarr@$TARGETSERVER:/export/home/tcarr/
echo "Time finished:  `date +%H:%M:%S`"

#Cleanup
rm garbage.txt
echo "Remember to remove the garbage.txt file on $TARGETSERVER."
