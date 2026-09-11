#!/usr/bin/env bash
 
# Variables
PREFIX=${PREFIX:-"Prefix"}
DIRECTORY=${DIRECTORY:-"."}
UNIT=${UNIT:-"chapter"}
LABEL=${LABEL:-""}
PATTERN=${PATTERN:-""}
ASSUME_YES=${ASSUME_YES:-"false"}
DRY_RUN=${DRY_RUN:-"false"}
 
## Per-unit defaults; capture group 1 is always the number.
## Patterns are matched against the filename with one leading space prepended,
## so "^.*[^A-Za-z0-9]" requires a separator before the marker while still
## allowing the marker to sit at the very start of the name.
CHAPTER_LABEL=${CHAPTER_LABEL:-"Chapter"}
CHAPTER_PATTERN=${CHAPTER_PATTERN:-'^.*[^A-Za-z0-9][Cc][Hh][A-Za-z]*\.?[[:space:][:punct:]]*0*([0-9]+(\.[0-9]+)?).*\.[Cc][Bb][Zz]$'}
VOLUME_LABEL=${VOLUME_LABEL:-"Volume"}
VOLUME_PATTERN=${VOLUME_PATTERN:-'^.*[^A-Za-z0-9][Vv][A-Za-z]*\.?[[:space:][:punct:]]*0*([0-9]+(\.[0-9]+)?).*\.[Cc][Bb][Zz]$'}
 
# Functions
 
## Verify required tooling is present
check_requirements() {
  local missing=()
  local cmd
 
  for cmd in cut find grep mkdir mv sed sort; do
    command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
  done
 
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "ERROR: missing required commands: ${missing[*]}" >&2
    exit 1
  fi
 
  if [[ ! -d "${DIRECTORY}" ]]; then
    echo "ERROR: not a directory: ${DIRECTORY}" >&2
    exit 1
  fi
}
 
## Collect matching CBZ files into the FILES array, ordered by number
collect_files() {
  local file
 
  FILES=()
 
  while IFS= read -r file; do
    FILES+=("${file#*|}")
  done < <(find "${DIRECTORY}" -maxdepth 1 -type f -printf ' %f\n' \
    | grep -E "${PATTERN}" \
    | sed -E "s/${PATTERN}/\1|&/" \
    | sort -t'|' -k1,1V \
    | cut -d'|' -f2- \
    | sed -E 's/^ //')
 
  if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No files matched in ${DIRECTORY}" >&2
    echo "Pattern: ${PATTERN}" >&2
    echo >&2
    echo "Files present (quoted, so stray whitespace is visible):" >&2
    find "${DIRECTORY}" -maxdepth 1 -type f -printf '  "%f"\n' >&2
    echo >&2
    echo "Try a different unit with -u, or a custom pattern with -r (group 1 on the number)." >&2
    exit 1
  fi
}
 
## Prompt the operator before touching anything
confirm() {
  local answer
 
  if [[ "${ASSUME_YES}" == "true" ]]; then
    return 0
  fi
 
  read -r -p "Proceed with ${#FILES[@]} file(s)? [y/N] " answer
  [[ "${answer}" =~ ^[Yy]([Ee][Ss])?$ ]]
}
 
## Build the destination directory name for a file
get_destination() {
  local file="${1}"
 
  echo "${PREFIX} - ${LABEL} $(get_number "${file}")"
}
 
## Extract the chapter or volume number from a filename
get_number() {
  local file="${1}"
 
  sed -E "s/${PATTERN}/\1/" <<<" ${file}"
}
 
## Create directories and move files into place
move_files() {
  local file
  local destination
 
  for file in "${FILES[@]}"; do
    destination="${DIRECTORY}/$(get_destination "${file}")"
 
    mkdir -p "${destination}" || { echo "ERROR: could not create ${destination}" >&2; continue; }
    mv -n -- "${DIRECTORY}/${file}" "${destination}/" \
      && echo "Moved: ${file}" \
      || echo "ERROR: could not move ${file}" >&2
  done
}
 
## Parse command line arguments
parse_args() {
  while getopts ":d:p:u:l:r:nyh" opt; do
    case "${opt}" in
      d) DIRECTORY="${OPTARG}" ;;
      p) PREFIX="${OPTARG}" ;;
      u) UNIT="${OPTARG}" ;;
      l) LABEL="${OPTARG}" ;;
      r) PATTERN="${OPTARG}" ;;
      n) DRY_RUN="true" ;;
      y) ASSUME_YES="true" ;;
      h) resolve_unit; usage; exit 0 ;;
      :) echo "ERROR: -${OPTARG} requires an argument" >&2; exit 1 ;;
      \?) echo "ERROR: unknown option: -${OPTARG}" >&2; exit 1 ;;
    esac
  done
}
 
## Fill in the label and pattern for the selected unit
resolve_unit() {
  case "${UNIT,,}" in
    chapter|ch|c)
      LABEL="${LABEL:-${CHAPTER_LABEL}}"
      PATTERN="${PATTERN:-${CHAPTER_PATTERN}}"
      ;;
    volume|vol|v)
      LABEL="${LABEL:-${VOLUME_LABEL}}"
      PATTERN="${PATTERN:-${VOLUME_PATTERN}}"
      ;;
    *)
      echo "ERROR: unknown unit: ${UNIT} (expected 'chapter' or 'volume')" >&2
      exit 1
      ;;
  esac
}
 
## Show what is about to happen
show_plan() {
  local file
 
  echo "Directory: ${DIRECTORY}"
  echo "Prefix:    ${PREFIX}"
  echo "Unit:      ${LABEL}"
  echo
  echo "The following moves will be made:"
 
  for file in "${FILES[@]}"; do
    printf '  %s  ->  %s/\n' "${file}" "$(get_destination "${file}")"
  done
 
  echo
}
 
## Print usage information
usage() {
  cat <<USAGE
Usage: $(basename "${0}") [-d DIRECTORY] [-p PREFIX] [-u UNIT] [-l LABEL] [-r PATTERN] [-n] [-y] [-h]
 
Sorts numbered CBZ files into "PREFIX - LABEL <number>" directories.
 
Options:
  -d DIRECTORY  Directory to operate on (default: ${DIRECTORY})
  -p PREFIX     Prefix for the created directories (default: ${PREFIX})
  -u UNIT       chapter or volume; sets the label and pattern (default: ${UNIT})
  -l LABEL      Override the directory label (default: ${LABEL})
  -r PATTERN    ERE matched against filenames; group 1 is the number.
                Filenames are matched with one leading space prepended
                (default: ${PATTERN})
  -n            Dry run; show the plan and exit without moving anything
  -y            Assume yes; skip the confirmation prompt
  -h            Show this help and exit
 
Examples:
  $(basename "${0}") -p "My Series"                  # My Series Ch. 01 -> "My Series - Chapter 1"
  $(basename "${0}") -p "My Series" -u volume        # My Series v01    -> "My Series - Volume 1"
  $(basename "${0}") -p "My Series" -u volume -l Bk  # My Series v01    -> "My Series - Bk 1"
 
Environment:
  PREFIX, DIRECTORY, UNIT, LABEL, PATTERN, ASSUME_YES, DRY_RUN override the
  defaults above; CHAPTER_LABEL, CHAPTER_PATTERN, VOLUME_LABEL and
  VOLUME_PATTERN override the per-unit presets.
USAGE
}
 
# Logic
parse_args "${@}"
resolve_unit
check_requirements
collect_files
show_plan
 
if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run; nothing moved."
  exit 0
fi
 
if confirm; then
  move_files
else
  echo "Aborted; nothing moved."
  exit 1
fi
