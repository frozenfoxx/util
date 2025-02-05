#!/usr/bin/env bash

# Variables

FORMAT=${FORMAT}
URL=${URL}
PREFIX=${PREFIX}
FILENAME=${FILENAME-%(title)s.%(ext)s}
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

  # Check for a URL to pull from
  if [[ -z "${URL}" ]]; then
    echo "You must supply a URL to download from!"
    exit 1
  fi
}

## Download video
download()
{
  if ! [[ -z ${USERNAME} ]]; then
    yt-dlp -f "${FORMAT}" --username "${USERNAME}" --password "${PASSWORD}" --write-thumbnail --write-subs -o "${PREFIX}${FILENAME}" "${URL}"
  else
    yt-dlp -f "${FORMAT}" --write-thumbnail --write-subs -o "${PREFIX}${FILENAME}" "${URL}"
  fi
}

## Select format
select_format()
{
  if ! [[ -z ${USERNAME} ]]; then
    yt-dlp --username "${USERNAME}" --password "${PASSWORD}" --list-formats "${URL}"
  else
    yt-dlp --list-formats "${URL}"
  fi

  read -p "Select format ([video][+audio]): " FORMAT
}

## Obtain credentials
get_credentials()
{
  if [[ -z ${USERNAME} ]]; then
    read -p "Username: " USERNAME
  fi

  if [[ -z ${PASSWORD} ]]; then
    read -sp "Password: " PASSWORD
  fi
}

## Display usage
usage()
{
  echo "Usage: [Environment Variables] download_web_video.sh [options]"
  echo "  Environment Variables:"
  echo "    FILENAME                                   set the format of the filename (default: %(title)s.%(ext)s)"
  echo "    PREFIX                                     set a prefix for the outputted file(s)"
  echo "    URL                                        set URL to download from"
  echo "  Options:"
  echo "    -f | --filename                            set the format of the filename (default: %(title)s.%(ext)s)"
  echo "    -h | --help                                display this usage information"
  echo "    -p | --prefix                              set a prefix for the outputted file(s)"
  echo "    -u | --url                                 set URL to download from"
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
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

check_commands
select_format
download
