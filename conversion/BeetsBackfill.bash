#!/usr/bin/env bash
#
# BeetsBackfill.bash
#
# Walks the Lidarr library and re-runs BeetsTagger.bash against every album that
# has FLAC files, so pre-existing releases pick up the MusicBrainz ARTIST_CREDIT
# handling that otherwise only fires on import.

# Variables

SCRIPT_VERSION=${SCRIPT_VERSION:-2.0}
SCRIPT_NAME=${SCRIPT_NAME:-BeetsBackfill}

# The arr-scripts functions file reads these two names directly
scriptVersion="$SCRIPT_VERSION"
scriptName="$SCRIPT_NAME"

EXTENDED_CONF=${EXTENDED_CONF:-/config/extended.conf}
FUNCTIONS_FILE=${FUNCTIONS_FILE:-/config/extended/functions}
BEETS_TAGGER=${BEETS_TAGGER:-/config/extended/BeetsTagger.bash}
STATE_FILE=${STATE_FILE:-/config/extended/BeetsBackfill.state}
WORKLIST_FILE=${WORKLIST_FILE:-/config/extended/BeetsBackfill.worklist}

REQUIRED_COMMANDS=${REQUIRED_COMMANDS:-curl jq metaflac ffprobe beet}

DELAY_SECONDS=${DELAY_SECONDS:-5}
ARTIST_DELAY_SECONDS=${ARTIST_DELAY_SECONDS:-0.2}
ASSUME_YES=${ASSUME_YES:-false}
DRY_RUN=${DRY_RUN:-false}
RESET_STATE=${RESET_STATE:-false}
ARTIST_FILTER=${ARTIST_FILTER:-}

QUEUED=0
SKIPPED_DONE=0
SKIPPED_NO_FILES=0
SKIPPED_NON_FLAC=0
PROCESSED=0
FAILED=0

# Functions

usage () {
	cat <<-EOF
	$SCRIPT_NAME $SCRIPT_VERSION

	Re-runs BeetsTagger against every FLAC album already in the Lidarr library,
	restoring the MusicBrainz artist credit (the "feat." part) to the ARTIST tag.

	Usage:
	  bash $(basename "$0") [options]

	Typically run inside the Lidarr container:
	  docker exec -it lidarr bash /config/extended/$(basename "$0") --dry-run
	  docker exec -it lidarr bash /config/extended/$(basename "$0")

	Options:
	  -y, --yes            Skip the confirmation prompt; required when stdin is not a terminal
	  -n, --dry-run        Build and report the worklist, change nothing
	  -d, --delay <sec>    Seconds to wait between albums (default: $DELAY_SECONDS)
	  -a, --artist <id>    Limit the run to a single Lidarr artist id
	  -r, --reset          Discard resume state and start from the beginning
	  -h, --help           Show this help

	Behaviour:
	  Albums with no files, and albums with no FLAC tracks, are skipped during
	  enumeration. Completed album ids are appended to the state file, so an
	  interrupted run resumes where it stopped. Albums are processed one at a
	  time because BeetsTagger recreates a shared beets library on each call.

	Files:
	  State     $STATE_FILE
	  Worklist  $WORKLIST_FILE

	Environment overrides:
	  EXTENDED_CONF, FUNCTIONS_FILE, BEETS_TAGGER, STATE_FILE, WORKLIST_FILE,
	  DELAY_SECONDS, ARTIST_DELAY_SECONDS, REQUIRED_COMMANDS
	EOF
}

die () {
	echo "ERROR :: $SCRIPT_NAME :: $1" >&2
	exit 1
}

parse_args () {
	while [ $# -gt 0 ]; do
		case "$1" in
			-y|--yes)     ASSUME_YES="true"; shift ;;
			-n|--dry-run) DRY_RUN="true"; shift ;;
			-d|--delay)   DELAY_SECONDS="${2:-}"; shift 2 ;;
			-a|--artist)  ARTIST_FILTER="${2:-}"; shift 2 ;;
			-r|--reset)   RESET_STATE="true"; shift ;;
			-h|--help)    usage; exit 0 ;;
			*)            echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
		esac
	done
}

check_requirements () {
	local cmd
	local missing=""

	for cmd in $REQUIRED_COMMANDS; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			missing="$missing $cmd"
		fi
	done

	if [ -n "$missing" ]; then
		die "Missing required command(s):$missing :: This script is meant to run inside the arr-scripts Lidarr container, where setup.bash installs them"
	fi

	if [ ! -f "$EXTENDED_CONF" ]; then
		die "$EXTENDED_CONF not found :: arr-scripts does not appear to be installed"
	fi

	if [ ! -f "$FUNCTIONS_FILE" ]; then
		die "$FUNCTIONS_FILE not found :: arr-scripts does not appear to be installed"
	fi

	if [ ! -f "$BEETS_TAGGER" ]; then
		die "$BEETS_TAGGER not found :: nothing to back-fill with"
	fi

	if ! echo "$DELAY_SECONDS" | grep -qE '^[0-9]+$'; then
		die "--delay must be a whole number of seconds, got \"$DELAY_SECONDS\""
	fi

	if [ -n "$ARTIST_FILTER" ] && ! echo "$ARTIST_FILTER" | grep -qE '^[0-9]+$'; then
		die "--artist must be a numeric Lidarr artist id, got \"$ARTIST_FILTER\""
	fi

	if [ ! -w "$(dirname "$STATE_FILE")" ]; then
		die "$(dirname "$STATE_FILE") is not writable :: cannot record resume state"
	fi
}

load_environment () {
	# shellcheck source=/dev/null
	source "$EXTENDED_CONF"
	# shellcheck source=/dev/null
	source "$FUNCTIONS_FILE"
	logfileSetup

	if [ "$enableBeetsTagging" != "true" ]; then
		die "enableBeetsTagging is not \"true\" in $EXTENDED_CONF :: BeetsTagger would exit immediately for every album"
	fi
}

init_arr_api () {
	arrUrl=""
	arrApiKey=""
	getArrAppInfo
	verifyApiAccess
}

prepare_state () {
	if [ "$RESET_STATE" == "true" ] && [ -f "$STATE_FILE" ]; then
		rm -f "$STATE_FILE"
		log "Resume state discarded"
	fi

	touch "$STATE_FILE"
	: > "$WORKLIST_FILE"
}

get_artist_ids () {
	if [ -n "$ARTIST_FILTER" ]; then
		echo "$ARTIST_FILTER"
		return
	fi

	curl -s "$arrUrl/api/v1/artist" -H "X-Api-Key: ${arrApiKey}" | jq -r '.[].id'
}

album_flac_count () {
	# $1 album id
	curl -s "$arrUrl/api/v1/trackFile?albumId=$1" -H "X-Api-Key: ${arrApiKey}" \
		| jq -r '[.[].path | select(test("\\.flac$"; "i"))] | length'
}

queue_artist_albums () {
	# $1 artist id
	local albumId albumTitle fileCount flacCount

	while IFS=$'\t' read -r albumId albumTitle fileCount; do
		[ -z "$albumId" ] && continue

		if [ "$fileCount" == "0" ] || [ "$fileCount" == "null" ]; then
			SKIPPED_NO_FILES=$(( SKIPPED_NO_FILES + 1 ))
			continue
		fi

		if grep -qx "$albumId" "$STATE_FILE"; then
			SKIPPED_DONE=$(( SKIPPED_DONE + 1 ))
			continue
		fi

		# BeetsTagger only handles FLAC; skip anything else rather than burn a run on it
		flacCount="$(album_flac_count "$albumId")"
		if [ -z "$flacCount" ] || [ "$flacCount" == "0" ]; then
			SKIPPED_NON_FLAC=$(( SKIPPED_NON_FLAC + 1 ))
			continue
		fi

		printf '%s\t%s\n' "$albumId" "$albumTitle" >> "$WORKLIST_FILE"
		QUEUED=$(( QUEUED + 1 ))
	done < <(curl -s "$arrUrl/api/v1/album?artistId=$1" -H "X-Api-Key: ${arrApiKey}" \
		| jq -r '.[] | [.id, .title, (.statistics.trackFileCount // 0)] | @tsv')
}

build_worklist () {
	local artistIds artistId

	log "Enumerating library..."

	artistIds="$(get_artist_ids)"
	if [ -z "$artistIds" ]; then
		die "No artists returned from Lidarr at $arrUrl"
	fi

	for artistId in $artistIds; do
		queue_artist_albums "$artistId"
		sleep "$ARTIST_DELAY_SECONDS"
	done
}

print_plan () {
	log "------------------------------------------------------------"
	log "Backfill plan"
	log "  Albums queued for tagging : $QUEUED"
	log "  Skipped, already done     : $SKIPPED_DONE"
	log "  Skipped, no files         : $SKIPPED_NO_FILES"
	log "  Skipped, no FLAC          : $SKIPPED_NON_FLAC"
	log "  Delay between albums      : ${DELAY_SECONDS}s"
	log "  Minimum runtime           : ~$(( (QUEUED * DELAY_SECONDS) / 60 )) min, plus beets processing per album"
	log "------------------------------------------------------------"
	log "This rewrites ARTIST / ALBUMARTIST tags in place on the FLAC files"
	log "listed in $WORKLIST_FILE. Existing tags are overwritten."
	log "------------------------------------------------------------"
}

confirm_or_exit () {
	local confirmation

	if [ "$QUEUED" == "0" ]; then
		log "Nothing to do :: Exiting..."
		exit 0
	fi

	if [ "$DRY_RUN" == "true" ]; then
		log "Dry run :: no changes made :: Exiting..."
		exit 0
	fi

	if [ "$ASSUME_YES" == "true" ]; then
		return
	fi

	if [ ! -t 0 ]; then
		die "Not running interactively and --yes was not supplied :: refusing to tag $QUEUED albums unattended"
	fi

	printf 'Proceed with tagging %s albums? Type "yes" to continue: ' "$QUEUED"
	read -r confirmation
	if [ "$confirmation" != "yes" ]; then
		log "Aborted at confirmation prompt :: Exiting..."
		exit 0
	fi
}

process_album () {
	# $1 album id, $2 album title
	log "[$PROCESSED/$QUEUED] :: $2 :: albumId $1 :: Processing..."

	if bash "$BEETS_TAGGER" "$1" < /dev/null; then
		echo "$1" >> "$STATE_FILE"
		return 0
	fi

	log "[$PROCESSED/$QUEUED] :: $2 :: ERROR :: BeetsTagger exited non-zero :: Not marked complete"
	return 1
}

process_albums () {
	local albumId albumTitle

	SECONDS=0

	# One at a time: BeetsTagger recreates a shared beets library on every call
	while IFS=$'\t' read -r albumId albumTitle <&3; do
		PROCESSED=$(( PROCESSED + 1 ))

		if ! process_album "$albumId" "$albumTitle"; then
			FAILED=$(( FAILED + 1 ))
		fi

		if [ "$PROCESSED" -lt "$QUEUED" ]; then
			sleep "$DELAY_SECONDS"
		fi
	done 3< "$WORKLIST_FILE"
}

print_summary () {
	local duration=$SECONDS

	log "------------------------------------------------------------"
	log "Processed    : $PROCESSED"
	log "Failed       : $FAILED"
	log "Runtime      : $(( duration / 3600 ))h $(( (duration % 3600) / 60 ))m $(( duration % 60 ))s"
	log "Resume state : $STATE_FILE"
	log "------------------------------------------------------------"
}

# Logic

parse_args "$@"
check_requirements
load_environment
init_arr_api
prepare_state
build_worklist
print_plan
confirm_or_exit
process_albums
print_summary

exit 0
