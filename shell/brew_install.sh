#!/usr/bin/env bash

# Install Homebrew

# Variables
HOSTNAME=$(hostname)
BREW_SCRIPT=${BREW_SCRIPT:-'https://raw.githubusercontent.com/Homebrew/install/master/install'}
LOG_PATH=${LOG_PATH:-'/var/root/log'}
STD_LOG='brew_hostname.log'
STD_LOG_ARG=">>${LOG_PATH}/${STD_LOG}"

# Functions

install()
{
  if [ ${PLATFORM} == 'Darwin' ]; then
    eval echo "[+] Installing Homebrew..." ${STD_LOG_ARG}
    echo | ruby -e "$(curl -fsSL ${BREW_SCRIPT})"
  else
    eval echo "[!] This platform is not supported yet" ${STD_LOG_ARG}
    exit 1
  fi
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
  echo "[+] Usage: [Environment Variables] brew_install.sh [-hn]"
  echo "[+]   Environment Variables:"
  echo "[+]     LOG_PATH              path for logs (default: '/var/root/log')"
  echo "[+]     BREW_SCRIPT           URL for the Homebrew install script (default: 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
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
