#!/usr/bin/env bash

# Controls SSHD

# Variables
PLATFORM=$(uname -s)
CTL_CMD=''
START_CMD=''
STATUS_CMD=''
STOP_CMD=''

if [ ${PLATFORM} == 'Darwin' ]; then
  CTL_CMD=$(which systemsetup)
  START_CMD="${CTL_CMD} -setremotelogin on"
  STATUS_CMD="${CTL_CMD} -getremotelogin"
  STOP_CMD="${CTL_CMD} -f -setremotelogin off"
else
  echo "[!] This platform is not supported yet"
  exit 1
fi

# Functions
enable()
{
  echo "[+] Enabling sshd..."
  eval ${START_CMD}
}

disable()
{
  echo "[+] Disabling sshd..."
  eval ${STOP_CMD}
}

status()
{
  STATUS=$(${STATUS_CMD} | grep -e "^.*On$")
  if [[ -z ${STATUS} ]]; then
    echo "[+] Status: stopped"
  else
    echo "[+] Status: running"
  fi
}

usage()
{
  echo "[+] Usage: [Environment Variables] sshd_ctl.sh [start|status|stop]"
}

# Logic

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    start )       enable
                  exit 0
                  ;;
    status )      status
                  exit 0
                  ;;
    stop )        disable
                  exit 0
                  ;;
    -h | --help ) usage
                  exit 0
                  ;;
    * )           usage
                  exit 1
  esac
  shift
done