#!/usr/bin/env bash

# Adds a user to an OSX install

# Variable defaults
USERNAME=''
PASSWORD=''
SHELL='/bin/bash'
UID=''
GID=''
PRIMARYGID=20 # "staff" group, standard for most users

# Functions
usage()
{
  echo "usage: create_user_osx.sh [-aupigh]"
  echo "  -a | --admin                  set user to be an administrator"
  echo "  -u | --user [USERNAME]        set username"
  echo "  -p | --password [PASSWORD]    set username"
  echo "  -i | --uid [UID]              set user ID number"
  echo "  -g | --gid [GID]              set group ID number"
  echo "  -h | --help                   display this help message"
}

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    -a | --admin)     PRIMARYGID=80 # "admin" group, standard for superusers
                      ;;
    -u | --user )     shift
                      USERNAME=$1
                      ;;
    -p | --password ) shift
                      PASSWORD=$1
                      ;;
    -i | --uid )      shift
                      UID=$1
                      ;;
    -g | --gid )      shift
                      GID=$1
                      ;;
    -h | --help )     usage
                      exit
                      ;;
    * )               usage
                      exit 1
  esac
  shift
done

# Logic
dscl . -create /Users/${USERNAME}
dscl . -create /Users/${USERNAME} UserShell ${SHELL}
dscl . -create /Users/${USERNAME} RealName "${USERNAME}"
dscl . -create /Users/${USERNAME} UniqueID "${UID}"
dscl . -create /Users/${USERNAME} PrimaryGroupID ${PRIMARYGID}
dscl . -create /Users/${USERNAME}t NFSHomeDirectory /Users/${USERNAME}
dscl . -passwd /Users/${USERNAME} ${PASSWORD}
mkdir -p /Users/${USERNAME}/.ssh
chmod 700 /Users/${USERNAME}/.ssh/
