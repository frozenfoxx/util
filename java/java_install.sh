#!/usr/bin/env bash

# Installs Java

# Functions

usage()
{
  echo "usage: [JAVA_VERSION=number] java_install.sh"
  echo "  JAVA_VERSION  sets to a specific version (optional)"
}

# Install Java for OSX
install_osx()
{
  /usr/local/bin/brew tap caskroom/versions
  /usr/local/bin/brew cask install java${JAVA_VERSION}
}

# Enable unlimited crypo for OSX
crypto_osx()
{
  sed -i '' '/^#crypto\.policy=unlimited$/s/^#//g' ${JAVA_HOME}/*/Contents/Home/jre/lib/security/java.security
}

# Variables

PLATFORM=$(uname -s)

case "${PLATFORM}" in
  Darwin*) DEFAULT_JAVA="8"
           JAVA_VERSION="${JAVA_VERSION:-${DEFAULT_JAVA}}"
           JAVA_HOME="/Library/Java/JavaVirtualMachines"
           ;;
  *)       usage
           exit 1
           ;;
esac

# Logic

case "${PLATFORM}" in
  Darwin*)  install_osx()
            crypto_osx()
            ;;
  *)        usage
            exit 1
            ;;
esac
