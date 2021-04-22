#!/usr/bin/env bash

# Variables
CLUSTER_AGENT_COUNT=${CLUSTER_AGENT_COUNT:-'1'}
CLUSTER_API_PORT=${CLUSTER_API_PORT:-'6443'}
CLUSTER_NAME=${CLUSTER_NAME:-'portainer'}
CLUSTER_SERVER_COUNT=${CLUSTER_SERVER_COUNT:-'1'}
CLUSTER_VOLUME=${CLUSTER_VOLUME:-'/data'}

# Functions

## Install k3d
install_k3d()
{
  echo "Installing k3d..."
  wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
}

## Install k3s
install_k3s()
{
  k3d cluster create ${CLUSTER_NAME} \
    --api-port ${CLUSTER_API_PORT} \
    --servers ${CLUSTER_SERVER_COUNT} \
    --agents ${CLUSTER_AGENT_COUNT} \
    --volume ${CLUSTER_VOLUME}:${CLUSTER_VOLUME} \
    -p 30000-32767:30000-32767@server[0]
    ## FIXME: do the whole server range, not just one server
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] install_k3s.sh [-h]"
  echo "  Environment Variables"
  echo "    CLUSTER_AGENT_COUNT              number of agents (default: '1')"
  echo "    CLUSTER_API_PORT                 API port (default: '6443')"
  echo "    CLUSTER_NAME                     name of the cluster (default: 'portainer')"
  echo "    CLUSTER_SERVER_COUNT             number of servers (default: '1')"
  echo "    CLUSTER_VOLUME                   mount for volumes (default: '/data')"
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

install_k3d
install_k3s
