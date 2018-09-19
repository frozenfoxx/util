#!/usr/bin/env bash

# Installs jq

# Variables
PLATFORM=$(uname -s)

# Functions

# Install jq for OSX
install_osx()
{
  /usr/local/bin/brew install jq
}

# Install jq for Linux
install_linux()
{
  /usr/bin/apt-get update && /usr/bin/apt-get install -y jq
}

# Show usage information
usage()
{
  echo "usage: jq_install.sh"
}

# Logic

case "${PLATFORM}" in
  Darwin* ) install_osx
            exit 0
            ;;
  Linux* )  install_linux
            exit 0
            ;;
  * )       usage
            exit 1
esac
