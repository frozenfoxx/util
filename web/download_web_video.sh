#!/usr/bin/env bash

# Variables

FORMAT=${FORMAT}
URL=${URL}
PREFIX=${PREFIX}
FILENAME=${FILENAME}
USERNAME=${USERNAME}
PASSWORD=${PASSWORD}

# Functions

## Verify we have all required tools
check_commands()
{
  # Check for yt-dlp
  if ! command -v yt-dlp &> /dev/null; then
    echo "yt-dlp could not be found!"
    exit 1
  fi
}

## Select formats
formats()
{
  yt-dlp --list-formats ${URL}
}

## Display usage
usage()
{
  echo "Usage: [Environment Variables] download_web_video.sh [options]"
  echo "  Environment Variables:"
  echo "    URL                                        set URL to download from"
  echo "  Options:"
  echo "    -h | --help                                display this usage information"
  echo "    --u | --url                                set URL to download from"
}

# Logic

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--url)
      URL="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--filename)
      FILENAME="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--prefix)
      PREFIX="$2"
      shift # past argument
      shift # past value
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    -h|--help)
      usage
      exit 0
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

check_commands

