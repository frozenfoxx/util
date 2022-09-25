#!/usr/bin/env bash
# Updates a Linode DNS domain

# Variables
DOMAIN=${DOMAIN:-"example.com"}
SUBDOMAIN=${SUBDOMAIN:-'*'}
TOKEN=${TOKEN:-''}

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

## Send a call to LiveDNS
update()
{
  # Retrieve external IP
  EXTERNAL_IP=$(curl -s ifconfig.me)

  # Get the domain's ID
  DOMAIN_ID=$(curl -H "Authorization: Bearer ${TOKEN}" "https://api.linode.com/v4/domains" | \
    jq --arg DOMAIN "${DOMAIN}" '.data[] | select(.domain == $DOMAIN) | .id')
  
  # Get the subdomain's ID
  SUBDOMAIN_ID=$(curl -H "Authorization: Bearer ${TOKEN}" "https://api.linode.com/v4/domains/${DOMAIN_ID}" | \
    jq --arg SUBDOMAIN "${SUBDOMAIN}" '.data[] | select(.subdomain == $SUBDOMAIN) | .id')

  # Update the A Record of the subdomain using PUT
  curl -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -X PUT -d '{
      "type": "A",
      "name": "${SUBDOMAIN}",
      "target": "${EXTERNAL_IP}",
      "priority": 50,
      "weight": 50,
      "port": 80,
      "service": null,
      "protocol": null,
      "ttl_sec": 604800,
      "tag": null
    }' \
    https://api.linode.com/v4/domains/${DOMAIN_ID}/records/${SUBDOMAIN_ID}
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
    -h | --help ) usage
                  exit 0
  esac
  shift
done

check_commands
update
