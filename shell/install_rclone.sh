#!/usr/bin/env bash

# Variables
RCLONE_PATH=${RCLONE_PATH:-'/usr/local/bin'}
RCLONE_URL=${RCLONE_URL:-'https://downloads.rclone.org/rclone-current-linux-amd64.zip'}

# Functions

## Install rclone
install()
{
  wget ${RCLONE_URL}
  unzip $(basename ${RCLONE_URL})
  cd rclone-*-linux-amd64

  cp rclone ${RCLONE_PATH}/
  chown root:root ${RCLONE_PATH}/rclone
  chmod 755 ${RCLONE_PATH}/rclone
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] install_rclone.sh [-h]"
  echo "  Environment Variables"
  echo "    RCLONE_PATH                filesystem location for rclone (default: '/usr/local/bin/')"
  echo "    RCLONE_URL                 location of the archive for rclone (default: 'https://downloads.rclone.org/rclone-current-linux-amd64.zip')"
}

# Logic

## Argument parsing
while [[ "$1" != "" ]]; do
  case $1 in
    -h | --help ) usage
                  exit 0
                  ;;
    * )           usage
                  exit 1
  esac
  shift
done

install
