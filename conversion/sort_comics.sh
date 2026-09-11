#!/usr/bin/env bash
 
# Variables
PREFIX=${PREFIX:-"Prefix"}
DIRECTORY=${DIRECTORY:-"."}
## ERE matched against each filename; capture group 1 is the chapter number
PATTERN=${PATTERN:-'^[Cc][Hh][A-Za-z]*\.?[[:space:][:punct:]]*0*([0-9]+(\.[0-9]+)?).*\.[Cc][Bb][Zz]$'}
ASSUME_YES=${ASSUME_YES:-"false"}
DRY_RUN=${DRY_RUN:-"false"}
 
# Functions
 
## Verify required tooling is present
check_requirements() {
  local missing=()
  local cmd
 
  for cmd in find grep mkdir mv sed sort; do
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
 
## Collect matching CBZ files into the FILES array
collect_files() {
  local file
 
  FILES=()
 
  while IFS= read -r file; do
    FILES+=("${file#*|}")
  done < <(find "${DIRECTORY}" -maxdepth 1 -type f -printf '%f\n' \
    | grep -E "${PATTERN}" \
    | sed -E "s/${PATTERN}/\1|&/" \
    | sort -t'|' -k1,1V \
    | cut -d'|' -f2-)
 
  if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No files matched in ${DIRECTORY}" >&2
    echo "Pattern: ${PATTERN}" >&2
    echo >&2
    echo "Files present (quoted, so stray whitespace is visible):" >&2
    find "${DIRECTORY}" -maxdepth 1 -type f -printf '  %f\n' | sed -E 's/^  (.*)$/  "\1"/' >&2
    echo >&2
    echo "Adjust the pattern with -r, keeping group 1 on the chapter number." >&2
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
 
## Extract the chapter number from a filename
get_chapter() {
  local file="${1}"
 
  sed -E "s/${PATTERN}/\1/" <<<"${file}"
}
 
## Build the destination directory name for a file
get_destination() {
  local file="${1}"
 
  echo "${PREFIX} - Chapter $(get_chapter "${file}")"
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
  while getopts ":d:p:r:nyh" opt; do
    case "${opt}" in
      d) DIRECTORY="${OPTARG}" ;;
      p) PREFIX="${OPTARG}" ;;
      r) PATTERN="${OPTARG}" ;;
      n) DRY_RUN="true" ;;
      y) ASSUME_YES="true" ;;
      h) usage; exit 0 ;;
      :) echo "ERROR: -${OPTARG} requires an argument" >&2; usage; exit 1 ;;
      \?) echo "ERROR: unknown option: -${OPTARG}" >&2; usage; exit 1 ;;
    esac
  done
}
 
## Show what is about to happen
show_plan() {
  local file
 
  echo "Directory: ${DIRECTORY}"
  echo "Prefix:    ${PREFIX}"
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
Usage: $(basename "${0}") [-d DIRECTORY] [-p PREFIX] [-r PATTERN] [-n] [-y] [-h]
 
Sorts "Ch. <number> ... .cbz" files into "PREFIX - Chapter <number>" directories.
 
Options:
  -d DIRECTORY  Directory to operate on (default: ${DIRECTORY})
  -p PREFIX     Prefix for the created directories (default: ${PREFIX})
  -r PATTERN    ERE matched against filenames; group 1 is the chapter number
                (default: ${PATTERN})
  -n            Dry run; show the plan and exit without moving anything
  -y            Assume yes; skip the confirmation prompt
  -h            Show this help and exit
 
Environment:
  PREFIX, DIRECTORY, PATTERN, ASSUME_YES, DRY_RUN override the defaults above.
USAGE
}
 
# Logic
parse_args "${@}"
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
 
