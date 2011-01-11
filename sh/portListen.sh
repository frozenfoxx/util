#!/bin/sh
## Name:		portListen.sh
## Author:		Chi Hung Chan (chihungchan.blogspot.com), FOXX (frozenfoxx@github.com)
## Date:		04/13/2009
## Description:  	Looks through /proc and lists files that are listening
##			on a specified port.  This is useful for OSes like Solaris
##			that do not provide lsof.

# Ensure proper usage
if [ $# -ne 1 ]; then
  echo "Usage: $0 <port number>"
  exit 1
fi
listen=$1

cd /proc

# Skip process 0
for i in [1-9][0-9]*
do
  pfiles $i 2>/dev/null | nawk -v listen=$listen '
    BEGIN {
      found=0
    }
    NR==1 {
      process=$0
    }
    /sockname/ && $NF == listen {
      getline
      if ( ! /peername/ ) {
        found=1
        exit
      }
    }
    END {
      if ( found == 1 ) {
        printf("%s\n",process)
      }
    }'
done
