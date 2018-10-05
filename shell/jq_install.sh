#!/usr/bin/env bash

# Installs jq

# Variables
PLATFORM=$(uname -s)
LOG_PATH=${LOG_PATH:-'/var/root/log'}
STD_LOG='jq_install.log'
STD_LOG_ARG=">>${LOG_PATH}/${STD_LOG}"

if [ ${PLATFORM} == 'Darwin' ]; then
  INSTALL_CMD="$(which brew) install"
elif [ ${PLATFORM} == 'Linux' ]; then
  INSTALL_CMD="$(which apt-get) update && $(which apt-get) install -y"
else
  eval echo "[!] This platform is not supported yet" ${STD_LOG_ARG}
  exit 1
fi

# Functions

# Install jq
install()
{
  eval echo "[+] Installing jq..." ${STD_LOG_ARG}
  eval ${INSTALL_CMD} jq
}

# Nulls the logging arguments to turn off logging
unset_logs()
{
  echo "[+] Running with no log option..."
  STD_LOG_ARG=''
}

# Display usage information
usage()
{
  echo "[+] Usage: [Environment Variables] jq_install.sh [-hn]"
  echo "[+]   Environment Variables:"
  echo "[+]     LOG_PATH              path for logs (default: '/var/root/log')"
}

# Logic

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    -n | --nolog ) unset_logs
                   ;;
    -h | --help )  usage
                   exit 0
  esac
  shift
done

install
