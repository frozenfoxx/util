#!/usr/bin/env bash

# Generates a Tools Library ISO 

# Variables

ISO_CMD=$(which mkisofs || which genisoimage)
PLATFORM=$(uname -s)
BUILD_DIR=${BUILD_DIR:-'/tmp/tools_library'}
OUTPUT_DIR="${OUTPUT_DIR:-'/tmp'}"

# Functions

# Create directory structure
build_dir_structure()
{
  echo "[+] Building directory structure..."
  mkdir -p ${BUILD_DIR}
  if [ ${BIN_DIR} ] ; then mkdir -p ${BUILD_DIR}/bin ; fi
  if [ ${PUPPET_DIR} ] ; then mkdir -p ${BUILD_DIR}/puppetlabs/code ; fi
  if [ ${HIERA_DIR} ] ; then mkdir -p ${BUILD_DIR}/puppetlabs/data ; fi
  if [ ${SALT_DIR} ] ; then mkdir -p ${BUILD_DIR}/salt ; fi
  if [ ${PILLAR_DIR} ] ; then mkdir -p ${BUILD_DIR}/pillar ; fi
}

# Build ISO
build_iso()
{
  echo "[+] Building ISO..."
  eval ${ISO_CMD} -lJR -V TOOLS -o ${OUTPUT_DIR}/tools_library.iso ${BUILD_DIR}

  echo "[+] ISO located in ${OUTPUT_DIR}"
}

# Check for command to create ISO files
check_iso_command()
{
  if [ ! ${ISO_CMD} ] ; then
    echo "[!] mkisofs or genisoimage command not found."
    if [ ${PLATFORM} == 'Darwin' ]; then
      echo "[!] Install with 'brew install cdrtools'"
    elif [ ${PLATFORM} == 'Linux' ]; then
      echo "[!] Install either mkisofs or genisoimage with your package manager"
    fi

    exit 1
  fi
}

# Clean the directory structure
clean_dir_structure()
{
  echo "[+] Cleaning up directory structure..."
  rm -rf ${BUILD_DIR}
}

# Load the contents of the ISO into the directory structure
load_contents()
{
  if [ ${BIN_DIR} ] ; then
    echo "[+] Loading binaries/scripts..."
    rsync -avP ${BIN_DIR}/* ${BUILD_DIR}/bin/
  fi

  if [ ${PUPPET_DIR} ] ; then
    echo "[+] Loading Puppet code..."
    rsync -avP ${PUPPET_DIR}/* ${BUILD_DIR}/puppetlabs/code/
  fi

  if [ ${HIERA_DIR} ] ; then
    echo "[+] Loading Hiera data..."
    rsync -avP ${HIERA_DIR}/* ${BUILD_DIR}/puppetlabs/data/
  fi

  if [ ${SALT_DIR} ] ; then
    echo "[+] Loading Salt code..."
    rsync -avP ${SALT_DIR}/* ${BUILD_DIR}/salt/
  fi

  if [ ${PILLAR_DIR} ] ; then
    echo "[+] Loading Pillar data..."
    rsync -avP ${PILLAR_DIR}/* ${BUILD_DIR}/pillar/
  fi
}

# Usage information
usage()
{
  echo "[+] Usage: [Environment Variables] gen_tools_iso.sh [options]"
  echo "[+]   --output [path]  path to dump resultant ISO (priority over OUTPUT_DIR)"
  echo "[+]   --bin [path]     path to binaries/scripts directory"
  echo "[+]   --puppet [path]  path to Puppet codebase"
  echo "[+]   --hiera [path]   path to hiera data"
  echo "[+]   --salt [path]    path to Salt codebase"
  echo "[+]   --pillar [path]  path to pillar data"
  echo "[+]   Environment Variables:"
  echo "[+]     BUILD_DIR      path to directory for creating the ISO layout (default: '/tmp/tools_library')"
  echo "[+]     OUTPUT_DIR     path to dump resultant ISO (default: '/tmp')"
}

# Logic

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    --bin )       shift
                  BIN_DIR="${1:-${BIN_DIR}}"
                  ;;
    --hiera )     shift
                  HIERA_DIR="${1:-${HIERA_DIR}}"
                  ;;
    --output )    shift
                  OUTPUT_DIR="${1:-${OUTPUT_DIR}}"
                  ;;
    --pillar )    shift
                  PILLAR_DIR="${1:-${PILLAR_DIR}}"
                  ;;
    --puppet )    shift
                  PUPPET_DIR="${1:-${PUPPET_DIR}}"
                  ;;
    --salt )      shift
                  SALT_DIR="${1:-${SALT_DIR}}"
                  ;;
    -h | --help ) usage
                  exit 0
                  ;;
    * )           usage
                  exit 1
  esac
  shift
done

# Step through creation
check_iso_command
build_dir_structure
load_contents
build_iso
clean_dir_structure
