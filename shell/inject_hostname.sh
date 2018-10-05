#!/usr/bin/env bash

# Ensures hostname exists in the hosts file

# Variables
HOSTNAME=$(hostname)
HOSTSFILE=${HOSTSFILE:-'/etc/hosts'}
LOCALHOST=${LOCALHOST:-'127.0.0.1'}
REGEXLOCALHOST=$(echo ${LOCALHOST} | sed 's/\./\\./g')
EXPRESSION="^${REGEXLOCALHOST}\s\+${HOSTNAME}$"
LOG_PATH=${LOG_PATH:-'/var/root/log'}
STD_LOG='inject_hostname.log'
STD_LOG_ARG=">>${LOG_PATH}/${STD_LOG}"

# Functions
status()
{
  eval echo "[+] Checking for hosts entry..." ${STD_LOG_ARG}
  grep -e ${EXPRESSION} ${HOSTSFILE}
}

inject()
{
  eval echo "[+] Injecting hostname..." ${STD_LOG_ARG}
  eval echo "${LOCALHOST} ${HOSTNAME}" >> ${HOSTSFILE}
}

usage()
{
  echo "[+] Usage: [Environment Variables] inject_hostname.sh"
  echo "[+]   Environment Variables:"
  echo "[+]     HOSTSFILE    location of hosts file (default: '/etc/hosts')"
  echo "[+]     LOCALHOST    IP for localhost (default: '127.0.0.1')"
}

# Logic

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    -h | --help ) usage
                  exit 0
                  ;;
    * )           usage
                  exit 1
  esac
  shift
done

# Check if hosts file exists
if ! [ -f ${HOSTSFILE} ]; then
  eval echo "[+] Hosts file does not exist, injecting into new file" ${STD_LOG_ARG}
  inject
  exit 0
fi

# Check to see if hosts entry exists
status

# If the entry doesn't exist, inject it
if [[ $? -eq 0 ]]; then
  eval echo "[+] Hostname already in ${HOSTSFILE}, no changes necessary." ${STD_LOG_ARG}
else
  inject
fi

