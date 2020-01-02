#!/usr/bin/env bash

# Adds a user to a MacOS system

# Variables
GID=${GID:-'20'}                         # 20 is the "staff" group, standard for most users
PASSWORD=${PASSWORD:-''}
SECONDARY_GROUPS=${SECONDARY_GROUPS:-''}
SHELL=${SHELL:-'/bin/bash'}
UID=${UID:-''}
USERNAME=${USERNAME:-''}
LOG_PATH=${LOG_PATH:-'/var/root/log'}
STD_LOG='create_user_macos.log'
STD_LOG_ARG=""

# Functions

## Create user
create_user()
{
  dscl . -create /Users/${USERNAME}
  dscl . -create /Users/${USERNAME} UserShell ${SHELL}
  dscl . -create /Users/${USERNAME} RealName "${USERNAME}"
  dscl . -create /Users/${USERNAME} UniqueID "${UID}"
  dscl . -create /Users/${USERNAME} PrimaryGroupID ${GID}
  dscl . -create /Users/${USERNAME} NFSHomeDirectory /Users/${USERNAME}
  
  if [[ ${PASSWORD} ]]; then dscl . -passwd /Users/${USERNAME} ${PASSWORD}; fi

  for GROUP in ${SECONDARY_GROUPS} ; do
    dseditgroup -o edit -t user -a ${USERNAME} ${GROUP}
  done

  # Create the user's home directory
  createhomedir -c -u ${USERNAME} > /dev/null

  # Create the SSH directory
  mkdir -p /Users/${USERNAME}/.ssh
  chmod 700 /Users/${USERNAME}/.ssh/

  # Create the LaunchAgents dir
  mkdir -p /Users/${USERNAME}/Library/LaunchAgents
  chown -R ${USERNAME} /Users/${USERNAME}/Library/LaunchAgents
}

## Dump environment variables to the user's profile
environment_vars()
{
  if [[ ${LC_ALL} ]]; then echo "LC_ALL=${LC_ALL}" >> /Users/${USERNAME}/.profile; fi
  if [[ ${ANDROID_HOME} ]]; then echo "ANDROID_HOME=${ANDROID_HOME}" >> /Users/${USERNAME}/.profile; fi
  if [[ ${AUTOMATED_BUILD_ENGINE} ]]; then echo "AUTOMATED_BUILD_ENGINE=${AUTOMATED_BUILD_ENGINE}" >> /Users/${USERNAME}/.profile; fi
  if [[ ${NUMBER_OF_PROCESSORS} ]]; then echo "NUMBER_OF_PROCESSORS=${NUMBER_OF_PROCESSORS}" >> /Users/${USERNAME}/.profile; fi
}

## Set logging on
set_logging()
{
  echo "Running with logging option..."
  STD_LOG_ARG=">>${LOG_PATH}/${STD_LOG}"
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] create_user_macos.sh [options]"
  echo "  Environment Variables:"
  echo "    GID                         default group (default: '20')"
  echo "    PASSWORD                    password for the user"
  echo "    SECONDARY_GROUPS            additional groups to add the user to"
  echo "    SHELL                       default user shell (default: '/bin/bash')"
  echo "    UID                         unique user ID"
  echo "    USERNAME                    name for the user"
  echo "  Options:"
  echo "    -a | --admin                set user to be an administrator (set GID to 80)"
  echo "    -h | --help                 display this help message"
  echo "    -L | --Log                  enable logging"
}

# Logic

## Argument parsing
while [[ "$1" != "" ]]; do
  case $1 in
    -a | --admin) GID=80 # "admin" group, standard for superusers
                  ;;
    -h | --help ) usage
                  exit
                  ;;
    -L | --Log )  set_logging
                  ;;
    * )           usage
                  exit 1
  esac
  shift
done

create_user
environment_vars

