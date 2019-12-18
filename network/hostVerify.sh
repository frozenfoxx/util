#!/usr/bin/env bash

# Verifies entries for a host on a chosen DNS host and domain.

# Variables
DNSROOT=${DNSROOT:-''}
DOMAIN=${DOMAIN:-''}
HOST=${HOST:-''}
IP=${IP:-''}

# Functions

## Check to see if the DNS root server responded
check_dnsroot()
{
  echo "${NAMESVRS}" | grep -e "Connection timed out" &>/dev/null
  
  if [[ $? -eq 0 ]] ; then
    echo "Error: DNS root nameserver did not respond."
    exit
  fi
}

## List nameservers
list_nameservers()
{
  echo "List of nameservers queried:"
  echo "${NAMESVRS}"
}

## Locate all nameservers for the given domain off a root nameserver
retrieve_nameservers()
{
  NAMESVRS=$(dig @$DNSROOT $DOMAIN ns +short | sed -e 's/\.$//g')

  # Check to see if we received any nameservers
  if [[ "${NAMESVRS}" == '' ]] ; then
    echo "Error: no nameservers returned. Please ensure that the domain is correct."
    exit 1
  fi
}

## Verify all arguments are received
verify_arguments()
{
  if [[ ${DNSROOT} == '' ]]; then
    echo "DNSROOT cannot be null"
    usage
    exit 1
  fi

  if [[ ${DOMAIN} == '' ]]; then
    echo "DOMAIN cannot be null"
    usage
    exit 1
  fi

  if [[ ${HOST} == '' ]]; then
    echo "HOST cannot be null"
    usage
    exit 1
  fi

  if [[ ${IP} == '' ]]; then
    echo "IP cannot be null"
    usage
    exit 1
  fi
}

## Verify all hosts and IPs for nameservers
verify_host()
{
  # Iterate through the nameserver responses we got
  for i in ${NAMESVRS}; do

    # Reset the flag
    FOUND=0
  
    # Get the IP results for a given host off the current nameserver
    RESPONSES=$(dig @$i $HOST +short)
  
    # Check the supplied IP against the responses we get from the nameservers
    for j in ${RESPONSES} ; do
      if [[ ${j} == ${IP} ]] ; then
        FOUND=1
      fi
    done
  
    # If we didn't find the IP for the hostname responses, dump error and die
    if [[ ${FOUND} == 0 ]] ; then
      echo "Error: unable to verify target IP."
      echo ""
      echo "Responses for ${HOST} from ${i}:"
      echo "${RESPONSES}"
      exit 1
    fi
  done
}

## Display usage
usage()
{
  echo "Usage: hostVerify.sh [-h] [options]"
  echo " Environment Variables:"
  echo "   DNSROOT                       root server to query"
  echo "   DOMAIN                        domain to query"
  echo "   HOST                          target host"
  echo "   IP                            target IP"
  echo " Options:"
  echo "   -h | --help                   display usage information"
  echo "   --dnsroot                     root server to query (overrides environment variable)"
  echo "   --domain                      domain to query (overrides environment variable)"
  echo "   --host                        target host (overrides environment variable)"
  echo "   --ip                          target IP (overrides environment variable)"
}

# Logic

## Argument parsing
while [[ ${#} > 0 ]]; do
  case $1 in
    --dnsroot )  DNSROOT="$2"
                 ;;
    --domain )   DOMAIN="$2"
                 ;;
    --host )     HOST="$2"
                 ;;
    --ip )       IP="$2"
                 ;;
    -h | --help ) usage
                 exit 0
  esac
  shift
done

verify_arguments
retrieve_nameservers
check_dnsroot
verify_host
list_nameservers
