#!/usr/bin/env bash
# Set the variables the skill's commands use. Source it in every new shell:
#   . <skill dir>/scripts/env.sh
# Sets FLINK_SOURCE_REPO, owner (GitHub login), upstream and fork (git remote names).

# shellcheck disable=SC1091
. "$HOME/flink-backport-workspaces/config.env"
: "${FLINK_SOURCE_REPO:?missing in config.env}"

_remote_of() {
  git -C "$FLINK_SOURCE_REPO" remote -v |
    awk -v repo="$1" '$3 == "(fetch)" && $2 ~ ("[:/]" repo "(\\.git)?$") { print $1; exit }'
}

owner=$(gh api user --jq .login)
upstream=$(_remote_of apache/flink)
fork=$(_remote_of "$owner/flink")
: "${upstream:?no remote for apache/flink in $FLINK_SOURCE_REPO}"
: "${fork:?no remote for $owner/flink in $FLINK_SOURCE_REPO}"
