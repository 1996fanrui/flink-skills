#!/usr/bin/env bash
# Call the backport tracker API with the token in ~/flink-backport-workspaces/config.env.
#
# Usage:
#   bash tracker.sh list <limit> <state> [<state>...]
#   bash tracker.sh update <FLINK-KEY> <minor-version> '<json>'

set -e
set -o pipefail

API_URL=https://fanrui.dev/api/flink/backports

usage() {
  sed -n '4,6p' "$0" >&2
  exit 2
}

# shellcheck disable=SC1091
. "$HOME/flink-backport-workspaces/config.env"
: "${FLINK_BACKPORT_API_TOKEN:?missing in config.env}"

call() {
  # The config file keeps the token out of the process list.
  curl --silent --show-error --fail-with-body \
    --config <(printf 'header = "Authorization: Bearer %s"\n' "$FLINK_BACKPORT_API_TOKEN") "$@"
}

command=${1:-}
[[ $# -gt 0 ]] && shift
case "$command" in
  list)
    [[ $# -ge 2 ]] || usage
    limit=$1
    shift
    query="limit=$limit"
    for state in "$@"; do
      query="$query&state=$state"
    done
    call "$API_URL?$query"
    ;;
  update)
    [[ $# -eq 3 ]] || usage
    call --request PATCH --header 'Content-Type: application/json' --data "$3" \
      "$API_URL/$1/$2"
    ;;
  *)
    usage
    ;;
esac
printf '\n'
