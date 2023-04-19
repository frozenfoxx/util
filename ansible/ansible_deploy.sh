#!/usr/bin/env bash

# Deploys hosts with Ansible

# Variables
ANSIBLE_REPO=${ANSIBLE_REPO:-"https://github.com/frozenfoxx/ansible-bricksandblocks.git"}
INVENTORY_PATH=${INVENTORY_PATH:-"inventory"}
PLAYBOOK=${PLAYBOOK:-""}
PRIVATE_SSH_KEY=${PRIVATE_SSH_KEY:-"~/.ssh/id_rsa"}
TARGET=${TARGET:-""}

# If cloning Inventory from a remote target is desired, specify configuration via environment variables.
#   This script will check for the TYPE key, otherwise it will leave it with dynamic environment
#   variable lookup for each role.
#   i.e. RCLONE_CONFIG_[TARGET]_[KEY]
#   RCLONE_CONFIG_INVENTORY_PROVIDER=s3
#   RCLONE_CONFIG_INVENTORY_ACCESS_KEY_ID=xxxxxxxxxxx
RCLONE_CONFIG_INVENTORY_TYPE=${RCLONE_CONFIG_INVENTORY_TYPE:-''}

# Functions

## Verify we have all required tools
check_commands()
{
  # Check for ansible-galaxy
  if ! command -v ansible-galaxy &> /dev/null; then
    echo "ansible-galaxy could not be found!"
    exit 1
  fi

  # Check for ansible-playbook
  if ! command -v ansible-playbook &> /dev/null; then
    echo "ansible-playbook could not be found!"
    exit 1
  fi

  # Check for git
  if ! command -v git &> /dev/null; then
    echo "git could not be found!"
    exit 1
  fi

  # Check for rclone if necessary
  if [[ ! -z ${RCLONE_CONFIG_INVENTORY_TYPE} ]]; then
    if ! command -v rclone &> /dev/null; then
      echo "rclone could not be found!"
      exit 1
    fi
  fi
}

## Clean up the Ansible repository
cleanup_repo()
{
  if [[ -d ./ansible ]]; then
    echo "Cleaning up Ansible repository..."
    rm -rf ./ansible
  fi
}

## Clone the Ansible Inventory
clone_inventory()
{
  echo "Cloning Inventory..."

  local _rclone_arguments=""

  # Configure the arguments to rclone
  for var in $(compgen -v | grep RCLONE_CONFIG_INVENTORY); do
    _rclone_arguments="${var}='${!var}' ${_rclone_arguments}"
  done

  # Run rclone with the arguments
  eval ${_rclone_arguments} rclone copy inventory:${INVENTORY_PATH}/ ./ansible/
}

## Clone the Ansible repository
clone_repo()
{
  echo "Cloning Ansible repo..."

  git clone ${ANSIBLE_REPO} ansible
}

## Run ansible-galaxy installer
run_galaxy()
{
  echo "Running ansible-galaxy installer..."

  ansible-galaxy install -p ./ansible/roles -r ./ansible/requirements.yml
  ansible-galaxy collection install -p ./ansible/roles -r ./ansible/requirements.yml
}

## Run a playbook against the target
run_playbook()
{
  echo "Running ${PLAYBOOK} against ${TARGET}..."

  ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i ${TARGET}, --private-key ${PRIVATE_SSH_KEY} ./ansible/${PLAYBOOK}
}

## Display usage
usage()
{
  echo "Usage: [Environment Variables] ansible_deploy.sh [options]"
  echo "  Environment Variables:"
  echo "    ANSIBLE_REPO                               git repo containing the Ansible codebase (default: \"https://github.com/frozenfoxx/ansible-bricksandblocks.git\")"
  echo "    INVENTORY_PATH                             path for cloning Inventory (optional)"
  echo "    PLAYBOOK                                   playbook name to run against TARGET"
  echo "    PRIVATE_SSH_KEY                            private SSH key to communicate with TARGET (default: \"~/.ssh/id_rsa\")"
  echo "    RCLONE_CONFIG_INVENTORY_TYPE               use rclone to clone Inventory by setting this and other remote config keys (optional)"
  echo "    TARGET                                     IP/FQDN of the target to configure"
  echo "  Options:"
  echo "    -h | --help                                display this usage information"
  echo "    --ansible-repo                             git repo containing the Ansible codebase (default: \"https://github.com/frozenfoxx/ansible-bricksandblocks.git\")"
  echo "    --inventory-path                           path for cloning Inventory (optional)"
  echo "    --playbook                                 playbook name to run against TARGET"
  echo "    --private_ssh_key                          private SSH key to communicate with TARGET (default: \"~/.ssh/id_rsa\")"
  echo "    --target                                   IP/FQDN of the target to configure"
}

# Logic

## Argument parsing
while [[ "$#" > 1 ]]; do
  case $1 in
    --ansible-repo )    ANSIBLE_REPO="$2"
                        ;;
    --inventory-path )  INVENTORY_PATH="$2"
                        ;;
    --playbook )        PLAYBOOK="$2"
                        ;;
    --private_ssh_key ) PRIVATE_SSH_KEY="$2"
                        ;;
    --target )          TARGET="$2"
                        ;;
    -h | --help )       usage
                        exit 0
  esac
  shift
done

check_commands
cleanup_repo
clone_repo

# If a bucket has been provided for Inventory, clone it
if [[ ! -z ${RCLONE_CONFIG_INVENTORY_TYPE} ]]; then
  clone_inventory
fi

# Install roles from Galaxy if available
if [[ -f ./ansible/requirements.yml ]]; then
  run_galaxy
fi

run_playbook
