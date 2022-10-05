#!/usr/bin/env bash
# Updates a Linode DNS domain

# Variables
DOMAIN=${DOMAIN:-"example.com"}
SUBDOMAIN=${SUBDOMAIN:-'*'}
TOKEN=${TOKEN:-''}
VERBOSE=''

# Functions

## Verify we have all required tools
check_commands()
{
  # Check for cURL
  if ! command -v curl &> /dev/null
  then
    echo "curl could not be found!"
    exit 1
  fi
  
  # Check for jq
  if ! command -v jq &> /dev/null
  then
    echo "jq could not be found!"
    exit 1
  fi
}

## Send a call to Linode DNS
update()
{
  # Retrieve external IP
  EXTERNAL_IP=$(curl -s ifconfig.me)

  # Get the domain's ID
  DOMAIN_ID=$(curl -H "Authorization: Bearer ${TOKEN}" "https://api.linode.com/v4/domains" | \
    jq --arg DOMAIN "${DOMAIN}" '.data[] | select(.domain == $DOMAIN) | .id')
  
  # Get the subdomain's ID
  SUBDOMAIN_ID=$(curl -H "Authorization: Bearer ${TOKEN}" "https://api.linode.com/v4/domains/${DOMAIN_ID}/records" | \
    jq --arg SUBDOMAIN "${SUBDOMAIN}" '.data[] | select(.name == $SUBDOMAIN) | .id')

  REQUEST_BODY="$(echo {} | jq \
    --arg SUBDOMAIN "${SUBDOMAIN}" \
    --arg EXTERNAL_IP "${EXTERNAL_IP}" \
    '. + { "type": "A",
           "name": $SUBDOMAIN,
           "target": $EXTERNAL_IP,
           "priority": 50,
           "weight": 50,
           "port": 80,
           "service": null,
           "protocol": null,
           "ttl_sec": 604800,
           "tag": null
         }' \
  )"

  # If verbose, dump debugging info
  if ! [[ -z ${VERBOSE} ]]; then
    echo "DOMAIN: ${DOMAIN}"
    echo "DOMAIN_ID: ${DOMAIN_ID}"
    echo "SUBDOMAIN: ${SUBDOMAIN}"
    echo "SUBDOMAIN_ID: ${SUBDOMAIN_ID}"
    echo "EXTERNAL_IP: ${EXTERNAL_IP}"
    echo "REQUEST_BODY: ${REQUEST_BODY}"
  fi

  # Update the A Record of the subdomain using PUT
  curl ${VERBOSE} -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -X PUT -d "${REQUEST_BODY}" \
    https://api.linode.com/v4/domains/${DOMAIN_ID}/records/${SUBDOMAIN_ID}
}

## Turns verbose mode on
verbose()
{
  VERBOSE='-v'
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] linodedns_update.sh [options]"
  echo "  Environment Variables:"
  echo "    DOMAIN                Domain hosted with Linode (default: example.com)"
  echo "    SUBDOMAIN             Subdomain to update DNS (default: '*')"
  echo "    TOKEN                 Linode.com API token or Personal Access Token"
  echo "  Options:"
  echo "    -h | --help           display this usage information"
}

# Logic
## Argument parsing
while [[ "$#" > 0 ]]; do
  case $1 in
    -h | --help )    usage
                     exit 0
		     ;;
    -v | --verbose ) verbose
  esac
  shift
done

check_commands
update
