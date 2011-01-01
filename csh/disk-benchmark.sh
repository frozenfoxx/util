#!/usr/bin/csh

## Name:	disk-benchmark.sh
## Author:	FOXX (frozenfoxx@github.com)
## Date:	01/24/2008
## Description:	this is a simple program to provide a quick look at disk
##  write performance onto and off of a file system.  Simply adjust the
##  variables at the top and run the script.  It will create a file to move
##  back and forth three times and report the time taken to achieve it.

## Variable Declarations
## ---------------------
## FILESIZE is the argument for size of the file
## FILENAME1 is the location for which the file to be created
## FILENAME2 is the location for which the file to be moved
## DIR1 is the directory where the FILENAME was created
## DIR2 is the directory to move the FILENAME to
## COUNTER is the amount of times to do the test
setenv FILESIZE 1024m
setenv FILENAME1 /export/home/garbage.txt
setenv FILENAME2 /var/garbage.txt
setenv DIR1 /export/home/		
setenv DIR2 /var/
setenv COUNTER 3

## Create the file
echo "Creating $FILENAME1..."
mkfile $FILESIZE $FILENAME1 

## Do $COUNTER times
while ($COUNTER) 
  ## Move the file
  echo "Moving the file from $DIR1 to $DIR2"
  echo "Time started:  `date +%H:%M:%S`"
  mv $FILENAME1 $DIR2
  echo "Time finished:  `date +%H:%M:%S`"

  ## Move the file back
  echo "Moving the file from $DIR2 to $DIR1"
  echo "Time started:  `date +%H:%M:%S`"
  mv $FILENAME2 $DIR1
  echo "Time finished:  `date +%H:%M:%S`"

  ## Decrement COUNTER  
  @ COUNTER = $COUNTER - 1 
end

## Clean up the file
echo "Cleaning up $FILENAME1..."
rm $FILENAME1
echo `ls $DIR1 | grep garbage.txt`
