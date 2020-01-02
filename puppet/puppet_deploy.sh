#!/usr/bin/env bash

# Deploys Puppet on Linux.

# Variables
DEBIAN_FRONTEND="noninteractive"
DISTRO=${DISTRO:-'ubuntu'}
FILES_DIR=${FILES_DIR:-'/data/files'}
PUPPET_REPO_GIT=${PUPPET_REPO_GIT:-"git@github.com:frozenfoxx/puppet-churchoffoxx.git"}
PUPPET_REPO_HOST=${PUPPET_REPO_HOST:-"github.com"}
PUPPET_REPO_KEY=${PUPPET_REPO_KEY:-""}
PUPPET_REPO_USER=${PUPPET_REPO_USER:-"frozenfoxx"}
RELEASE=${RELEASE:-'bionic'}

# Functions

## Clean out SSH as it's no longer needed
cleanup_ssh()
{
  echo "Cleaning up SSH..."

  rm -rf /root/.ssh
}

## Configure SSH config and move SSH key
configure_ssh()
{
  # Create SSH directory
  if ! [[ -d /root/.ssh ]]; then
    echo "Creating root SSH configuration directory..."
    mkdir -p /root/.ssh
    chown root:root /root/.ssh
    chmod 700 /root/.ssh
  fi

  # Set up the key correctly
  echo "${PUPPET_REPO_KEY}" > /root/.ssh/ssh_key
  chown root:root /root/.ssh/ssh_key
  chmod 600 /root/.ssh/ssh_key

  # Create config
  (
  cat <<EOF
Host ${PUPPET_REPO_HOST}
  StrictHostKeyChecking no
  User ${PUPPET_REPO_USER}
  IdentityFile ~/.ssh/ssh_key
EOF
  ) > /root/.ssh/config

  # Ensure permissions on the config
  chown root:root /root/.ssh/config
  chmod 644 /root/.ssh/config
}

## Deploy the hieradata files
deploy_hieradata()
{
  # Check for the data directory
  if ! [[ -d /etc/puppetlabs/code/environments/production/data ]]; then
    echo "Data directory not found, creating..."
    mkdir -p /etc/puppetlabs/code/environments/production/data
  fi

  # Move the hieradata files into place
  mv ${FILES_DIR}/hiera/* /etc/puppetlabs/code/environments/production/data/
}

## Deploy the latest environment
deploy_r10k()
{
  # Deploy environments
  /opt/puppetlabs/puppet/bin/r10k deploy environment --puppetfile
}

## Install selector
install()
{
  if [[ ${DISTRO} == 'ubuntu' ]]; then
    install_ubuntu
    install_r10k
  else
    echo "This distro is not supported at this time."
    exit 1
  fi
}

## Install for Ubuntu
install_ubuntu()
{
  # Get the package
  wget https://apt.puppetlabs.com/puppet6-release-${RELEASE}.deb
  dpkg -i puppet6-release-${RELEASE}.deb
  rm puppet6-release-${RELEASE}.deb

  # Install the packages
  apt-get update && \
    apt-get install -y git puppet-agent
}

## Install r10k for dynamic environments
install_r10k()
{
  # Use Puppet's gem command to install
  /opt/puppetlabs/puppet/bin/gem install r10k

  # Create configuration directory
  mkdir -p /etc/puppetlabs/r10k

  # Create r10k.yaml
  (
  cat <<EOF
# The location to use for storing cached Git repos
:cachedir: '/var/cache/r10k'

# A list of git repositories to create
:sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppetlabs/code/environments
  :churchoffoxx:
    remote: "${PUPPET_REPO_GIT}"
    basedir: "/etc/puppetlabs/code/environments"
EOF
  ) > /etc/puppetlabs/r10k/r10k.yaml
}

## Display usage
usage()
{
  echo "Usage: puppet_deploy.sh [-h]"
  echo "  Environment Variables:"
  echo "    DISTRO                Linux distro to serve (default: 'ubuntu')"
  echo "    LOG_PATH              base directory for logging if enabled (default: \"/root/log\")"
  echo "    PUPPET_REPO_GIT       git repo containing the Puppet codebase (default: \"git@github.com:frozenfoxx/puppet-churchoffoxx.git\")"
  echo "    PUPPET_REPO_HOST      FQDN of the git repo containing the Puppet codebase (default: \"github.com\")"
  echo "    PUPPET_REPO_KEY       SSH key for accessing PUPPET_REPO_GIT"
  echo "    PUPPET_REPO_USER      user for cloning the Puppet codebase (default: \"frozenfoxx\")"
  echo "    RELEASE               release codename for distro (default: \"bionic\")"
  echo "  Options:"
  echo "    -h | --help            display this usage information"
  echo "    --distro               Linux distro to serve (override environment variable if present)"
  echo "    --puppet-repo-git      git repo containing the Puppet codebase (override environment variable if present)"
  echo "    --puppet-repo-host     FQDN of the git repo containing the Puppet codebase (override environment variable if present)"
  echo "    --puppet-repo-key      SSH key for accessing PUPPET_REPO_GIT (override environment variable if present)"
  echo "    --puppet-repo-user     user for cloning the Puppet codebase (override environment variable if present)"
  echo "    --release              release of the distro (override environment variable if present)"
}

# Logic

## Argument parsing
while [[ "$#" > 1 ]]; do
  case $1 in
    --distro )         DISTRO="$2"
                       ;;
    --puppet-repo-git )  PUPPET_REPO_GIT="$2"
                         ;;
    --puppet-repo-host ) PUPPET_REPO_HOST="$2"
                         ;;
    --puppet-repo-key )  PUPPET_REPO_KEY="$2"
                         ;;
    --puppet-repo-user ) PUPPET_REPO_USER="$2"
                         ;;
    --release )          RELEASE="$2"
                         ;;
    -h | --help )        usage
                         exit 0
  esac
  shift
done

install
configure_ssh
deploy_r10k
cleanup_ssh
deploy_hieradata
