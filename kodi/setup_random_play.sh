#!/usr/bin/env bash

# Configure Kodi's Play Random Videos add-on (script.playrandomvideos) for
# endless shuffle: turn on continuous play, add a source covering the whole
# media tree, and add favourites for random movies, episodes, and everything.
# Run on the Kodi host as root, with edit_kodi_xml.py beside it; safe to re-run.

set -Eeuo pipefail

# Variables
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EDIT_XML=${EDIT_XML:-${SCRIPT_DIR}/edit_kodi_xml.py}
KODI_USER=${KODI_USER:-kodi}
KODI_SERVICE=${KODI_SERVICE:-kodi}
KODI_HOME=${KODI_HOME:-/home/${KODI_USER}/.kodi}
ADDON_ID=${ADDON_ID:-script.playrandomvideos}
MEDIA_ROOT=${MEDIA_ROOT:-/data/Videos/}
SOURCE_NAME=${SOURCE_NAME:-All Videos}
CONTINUOUS_PLAY=${CONTINUOUS_PLAY:-true}
STOP_KODI=${STOP_KODI:-false}
DRY_RUN=${DRY_RUN:-false}
BACKUP_SUFFIX=${BACKUP_SUFFIX:-.bak-$(date +%Y%m%d%H%M%S)}

USERDATA="${KODI_HOME}/userdata"
SETTINGS_FILE="${USERDATA}/addon_data/${ADDON_ID}/settings.xml"
SOURCES_FILE="${USERDATA}/sources.xml"
FAVOURITES_FILE="${USERDATA}/favourites.xml"
KODI_WAS_RUNNING=false

# Functions

## Print a timestamped message
log()
{
    echo "[$(date +%T)] $*"
}

## Report the command that failed, so set -e never exits silently
on_error()
{
    echo "ERROR: line $1: \"$2\" exited with status $3" >&2
}

## Print an error and exit
die()
{
    echo "ERROR: $*" >&2
    exit 1
}

## Check for required tools, the add-on, and a stopped Kodi
check_requirements()
{
    [ "$(id -u)" -eq 0 ] || die "run as root (Kodi's files belong to ${KODI_USER})"
    for cmd in python3 systemctl; do
        command -v "$cmd" >/dev/null || die "$cmd not found"
    done
    [ -r "$EDIT_XML" ] || die "${EDIT_XML} not found; keep edit_kodi_xml.py beside this script or set EDIT_XML"
    id "$KODI_USER" >/dev/null 2>&1 || die "user ${KODI_USER} does not exist"
    [ -d "${KODI_HOME}/addons/${ADDON_ID}" ] || die "${ADDON_ID} is not installed in ${KODI_HOME}/addons"
    [ -d "$MEDIA_ROOT" ] || die "MEDIA_ROOT ${MEDIA_ROOT} is not a directory"

    # Kodi rewrites favourites.xml and sources.xml on exit, clobbering edits made while it runs
    if systemctl is-active --quiet "$KODI_SERVICE" || pgrep -x kodi.bin >/dev/null; then
        [ "$STOP_KODI" = true ] || die "Kodi is running; stop it first or rerun with STOP_KODI=true"
        KODI_WAS_RUNNING=true
    fi
}

## Run the XML editor; see edit_kodi_xml.py --help for its subcommands
edit_xml()
{
    python3 -I "$EDIT_XML" "$@"
}

## Stop Kodi if allowed, so it doesn't overwrite the edits
stop_kodi()
{
    [ "$KODI_WAS_RUNNING" = true ] || return 0
    [ "$DRY_RUN" = true ] && { log "Would stop ${KODI_SERVICE}"; return 0; }
    log "Stopping ${KODI_SERVICE}"
    systemctl stop "$KODI_SERVICE"
}

## Apply all settings, sources, and favourites
configure()
{
    [ "$DRY_RUN" = true ] || install -d -o "$KODI_USER" -g "$KODI_USER" "$(dirname "$SETTINGS_FILE")"

    log "Add-on settings (${SETTINGS_FILE})"
    edit_xml setting "$SETTINGS_FILE" continuous_play "$CONTINUOUS_PLAY"

    log "Sources (${SOURCES_FILE})"
    # No content type, so the library scanner leaves it alone; the add-on needs
    # it because JSON-RPC only lists directories inside a defined source
    edit_xml source "$SOURCES_FILE" "$SOURCE_NAME" "$MEDIA_ROOT"

    log "Favourites (${FAVOURITES_FILE})"
    edit_xml favourite "$FAVOURITES_FILE" "Random Movie" \
        "RunScript(${ADDON_ID},\"videodb://movies/titles/\",\"label=Movies\")" --thumb DefaultMovies.png
    edit_xml favourite "$FAVOURITES_FILE" "Random Episode" \
        "RunScript(${ADDON_ID},\"videodb://tvshows/titles/\",\"label=TV Shows\")" --thumb DefaultTVShows.png
    edit_xml favourite "$FAVOURITES_FILE" "Shuffle Everything" \
        "RunScript(${ADDON_ID},\"${MEDIA_ROOT}\",\"label=${SOURCE_NAME}\")" --thumb DefaultVideo.png

    [ "$DRY_RUN" = true ] || chown "$KODI_USER:$KODI_USER" "$SETTINGS_FILE" "$SOURCES_FILE" "$FAVOURITES_FILE"
}

## Start Kodi again if this script stopped it
start_kodi()
{
    [ "$KODI_WAS_RUNNING" = true ] || return 0
    [ "$DRY_RUN" = true ] && { log "Would start ${KODI_SERVICE}"; return 0; }
    log "Starting ${KODI_SERVICE}"
    systemctl start "$KODI_SERVICE"
}

# Logic

trap 'on_error "$LINENO" "$BASH_COMMAND" "$?"' ERR
export DRY_RUN BACKUP_SUFFIX

check_requirements
stop_kodi
configure
start_kodi

[ "$DRY_RUN" = true ] && log "Dry run; nothing changed" || log "Done"
