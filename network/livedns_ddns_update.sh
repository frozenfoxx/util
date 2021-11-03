#!/usr/bin/env bash
# Updates a Gandi LiveDNS domain
# Original version: https://virtuallytd.com/post/dynamic-dns-using-gandi/

# Variables
API_KEY=${API_KEY:-''}
DOMAIN=${DOMAIN:-"example.com"}
SUBDOMAIN=${SUBDOMAIN:-'*'}

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

  # Get the current zone HREF
  CURRENT_ZONE_HREF=$(curl -s -H "X-Api-Key: $API_KEY" https://dns.api.gandi.net/api/v5/domains/${DOMAIN} | jq -r '.zone_records_href')

  # Update the A Record of the subdomain using PUT
  curl -D- -X PUT -H "Content-Type: application/json" \
    -H "X-Api-Key: ${API_KEY}" \
    -d "{\"rrset_name\": \"${SUBDOMAIN}\",
      \"rrset_type\": \"A\",
      \"rrset_ttl\": 1200,
      \"rrset_values\": [\"${EXTERNAL_IP}\"]}" \
    ${CURRENT_ZONE_HREF}/${SUBDOMAIN}/A
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] livedns_ddns_update.sh [options]"
  echo "  Environment Variables:"
  echo "    API_KEY               Gandi.net LiveDNS API key"
  echo "    DOMAIN                Domain hosted with Gandi (default: example.com)"
  echo "    SUBDOMAIN             Subdomain to update DNS (default: '*')"
  echo "  Options:"
  echo "    -h | --help            display this usage information"
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
