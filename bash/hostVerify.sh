#!/bin/bash
## Name:          hostVerify.sh
## Author:        FOXX (frozenfoxx@github.com)
## Date:          05/19/2010
## Description:   this simple bash script verifies entries for a host on
##                a chosen DNS host and domain.

# Verify number of arguments
if [ $# -lt 4 ] ; then

  # Print usage and exit
  echo "Incorrect number of arguments."
  echo "Usage:"
  echo "hostVerify.sh <DNS root> <domain> <target host> <target IP>"

  exit

fi

# VARIABLES
DNSROOT=$1
DOMAIN=$2
HOST=$3
IP=$4

# Locate all nameservers for the given domain off a root nameserver
NAMESVRS=`dig @$DNSROOT $DOMAIN ns +short | sed -e 's/\.$//g'`

# Check to see if the DNS root server responded
echo "$NAMESVRS" | grep -e "connection timed out" &>/dev/null

if [ $? -eq 0 ] ; then
  echo "ERROR"
  echo "DNS root nameserver did not respond."
  exit
fi

# Check to see if we received any nameservers
if [ "$NAMESVRS" == ""  ] ; then
  echo "ERROR"
  echo "No nameservers returned.  Please check that the domain is correct."
  exit
fi

# Iterate through the nameserver responses we got
for i in $NAMESVRS ; do 

  # Reset the flag
  FOUND=0

  # Get the IP results for a given host off the current nameserver
  RESPONSES=`dig @$i $HOST +short`

  # Check the supplied IP against the responses we get from the nameservers
  for j in $RESPONSES ; do 
    if [ $j == $IP ] ; then 
      FOUND=1
    fi
  done

  # If we didn't find the IP for the hostname responses, dump error and die
  if [ $FOUND == 0 ] ; then
    echo "ERROR"
    echo "Unable to verify target IP."
    echo "Responses for $HOST from $i:"
    echo "$RESPONSES"
    exit
  fi

done

# No problems were detected
echo "OK"
echo "List of nameservers queried:"
echo "$NAMESVRS"
exit
