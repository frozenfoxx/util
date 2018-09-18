#!/usr/bin/env bash

# Controls Packet Filter

# Variables
PLATFORM=$(uname -s)
CTL_CMD=''
RESTART_CMD=''
START_CMD=''
STATUS_CMD=''
STOP_CMD=''

if [ ${PLATFORM} == 'Darwin' ]; then
  CTL_CMD=$(which pfctl)
  RESTART_CMD="${CTL_CMD} -d && ${CTL_CMD} -F all && ${CTL_CMD} -f /etc/pf.conf && ${CTL_CMD} -e"
  START_CMD="${CTL_CMD} -F all && ${CTL_CMD} -f /etc/pf.conf && ${CTL_CMD} -e || true"
  STATUS_CMD="${CTL_CMD} -s info 2>/dev/null | grep Status | [ \$(awk '{print \$2}') == Enabled ]"
  STOP_CMD="${CTL_CMD} -d || true"
else
  echo "[!] This platform is not supported yet"
  exit 1
fi

# Functions
enable()
{
  echo "[+] Enabling pf..."
  eval ${START_CMD}
}

disable()
{
  echo "[+] Disabling pf..."
  eval ${STOP_CMD}
}

restart()
{
  echo "[+] Restarting pf..."
  eval ${RESTART_CMD}
}

status()
{
  eval ${STATUS_CMD}
  if [[ $? > 0 ]]; then
    echo "[+] Status: stopped"
  else
    echo "[+] Status: running"
  fi
}

usage()
{
  echo "[+] Usage: pfctl_ctl.sh [restart|start|status|stop]"
}

# Logic

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    restart )     restart
                  exit 0
                  ;;
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