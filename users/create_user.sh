#!/usr/bin/env bash

# Variables
AUTHKEYS=${AUTHKEYS:-''}
PASSWORD=${PASSWORD:-''}
SHELL=${SHELL:-'/bin/bash'}
USERNAME=${USERNAME:-''}

# Functions

## Create the user
create_user()
{
  useradd -m -d /home/${USERNAME} -s /bin/bash ${USERNAME}
  echo -e "${PASSWORD}\n${PASSWORD}" | passwd ${USERNAME}
  usermod -aG sudo ${USERNAME}
  mkdir -p /home/${USERNAME}/.ssh
  chmod 700 /home/${USERNAME}
  chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

  # Check if an authorized_keys file has been supplied
  if [[ -n ${AUTHKEYS} ]]; then
    echo ${AUTHKEYS} > /home/${USERNAME}/.ssh/authorized_keys
    chmod 644 /home/${USERNAME}/.ssh/authorized_keys
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh/authorized_keys
  fi
}

# Remove encoding on variables
decode_vars()
{
  AUTHKEYS=$(echo ${AUTHKEYS:-''} | base64 -d)
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] create_user.sh [options]"
  echo "  Environment Variables:"
  echo "    AUTHKEYS               set the contents of a [user home]/.ssh/authorized_keys  (note: must be base64 encoded)"
  echo "    USERNAME               set the username (default: admin)"
  echo "    PASSWORD               set a password for the user"
  echo "    SHELL                  set a shell (default: /bin/bash)"
  echo "  Options:"
  echo "    -h | --help            display this usage information"
  echo "    --authkeys             set the contents of a [user home]/.ssh/authorized_keys (override environment variable if present, base64 encoded)"
  echo "    --username             set the username (override environment variable if present)"
  echo "    --password             set a password for the user (override environment variable if present)"
  echo "    --shell                set a shell (override environment variable if present)"
}


# Logic

## Argument parsing
while [[ ${#} > 0 ]]; do
  case $1 in
    --authkeys )  AUTHKEYS="$2"
                  ;;
    --username )  USERNAME="$2"
                  ;;
    --password )  PASSWORD="$2"
                  ;;
    --shell )     SHELL="$2"
                  ;;
    -h | --help ) usage
                  exit 0
  esac
  shift
done

decode_vars
create_user
