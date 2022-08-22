#!/usr/bin/env bash

# Variables
BACKUP_PATH=${BACKUP_PATH:-'/data'}
DATE=$(/bin/date +%m%d%Y-%H%M)
NUM_BACKUPS=${NUM_BACKUPS:-'3'}
VMID=${VMID:-''}
LOG_PATH=${LOG_PATH:-'/var/log'}
STD_LOG=${STD_LOG:-'backup_lxc_btserver.log'}
STD_LOG_ARG=''

# Functions

## Clean up after the backup has been safely pulled
cleanup()
{
  # Set the number of backups incremented by one so it works properly with tail
  local __tail_backups=$((${NUM_BACKUPS}+1))

  # Remove backups within the container
  eval echo "Cleaning up backups within the container..." ${STD_LOG_ARG}
  /usr/sbin/pct exec ${VMID} /bin/sh -- -c "sudo -u btserver -i /bin/rm /home/btserver/lgsm/backup/*.tar.gz"

  # Check if successful
  if [[ $? -gt 0 ]]; then
    eval echo "Something went wrong, aborting!" ${STD_LOG_ARG}
    exit 1
  fi

  # Remove all but the newest archives
  eval echo "Removing all but the newest backups..." ${STD_LOG_ARG}
  (cd ${BACKUP_PATH} && ls -tp | grep -v '/$' | tail -n +${__tail_backups} | xargs -d '\n' -r rm --)

  # For BSD and MacOS
  #(cd ${BACKUP_PATH} && ls -tp | grep -v '/$' | tail -n +${__tail_backups} | tr '\n' '\0' | xargs -0 rm --)
  
  # Check if successful
  if [[ $? -gt 0 ]]; then
    eval echo "Something went wrong, aborting!" ${STD_LOG_ARG}
    exit 1
  fi
}

## Create the backup
create()
{
  eval echo "Creating backup..." ${STD_LOG_ARG}

  /usr/sbin/pct exec ${VMID} /bin/sh -- -c "sudo -u btserver -i /home/btserver/btserver backup"

  # Check if successful
  if [[ $? -gt 0 ]]; then
    eval echo "Something went wrong, aborting!" ${STD_LOG_ARG}
    exit 1
  fi
}

## Pull the backup onto the host
pull()
{
  if ! [[ -d "${BACKUP_PATH}" ]]; then
    eval echo "Backup path did not exist, creating..." ${STD_LOG_ARG}
    mkdir -p ${BACKUP_PATH}
  fi

  eval echo "Pulling the backup..." ${STD_LOG_ARG}
  
  /usr/sbin/pct pull ${VMID} /home/btserver/lgsm/backup/*.tar.gz ${BACKUP_PATH}/
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
  echo "Usage: [Environment Variables] ./backup_lxc_btserver.sh [-hL] --vmid [VMID] --backup-path [path]"
  echo "  Environment Variables:"
  echo "    BACKUP_PATH            path for backups (default: '/data')"
  echo "    LOG_PATH               path for logs (default: '/var/log')"
  echo "    NUM_BACKUPS            number of backup archives to retain (default: '3')"
  echo "    VMID                   VM identification number"
  echo "  Options:"
  echo "    --backup-path [path]   path for backups (default: '/data')"
  echo "    -h | --help            display this usage information"
  echo "    -L | --Log             enable logging (target: '[LOG_PATH]/backup_lxc_btserver.log')"
  echo "    --num-backups [num]    number of backup archives to retain (default: '3')"
  echo "    --vmid [VMID]          VM identification number"
}

# Logic

## Argument parsing
while [[ "$1" != "" ]]; do
  case $1 in
    --backup-path ) shift
                    BACKUP_PATH=$1
                    ;;
    -h | --help )   usage
                    exit 0
                    ;;
    -L | --Log )    set_logging
                    ;;
    --num-backups ) shift
                    NUM_BACKUPS=$1
                    ;;
    --vmid )        shift
                    VMID=$1
                    ;;
  esac
  shift
done

create
pull
cleanup
