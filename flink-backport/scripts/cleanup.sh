#!/usr/bin/env bash
# Remove backport environments that prepare.sh created and nobody uses any more.
#   bash <skill dir>/scripts/cleanup.sh
# A scheduler runs it before and after each run; its runs must not overlap.
# Removes every "scheduled" environment, which belongs to a finished or the just-finished run,
# and every "manual" one prepared more than 24 hours ago. Then deletes local backport/* branches
# that no worktree has checked out. Anything it cannot remove is reported and skipped.

set -e
set -o pipefail

tasks_dir="$HOME/flink-backport-workspaces/tasks"
# shellcheck disable=SC1091
. "$HOME/flink-backport-workspaces/config.env"
: "${FLINK_SOURCE_REPO:?missing in config.env}"

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

# The marker goes last, so a failed removal is retried by the next cleanup.
remove_environment() {
  local worktree=$1
  if [[ -e "$worktree" ]]; then
    git -C "$FLINK_SOURCE_REPO" worktree remove --force "$worktree" || rm -rf "$worktree" || return 1
  fi
  rm -rf "$worktree.m2" || return 1
  rm -f "$worktree.owner"
}

remove_environments() {
  local marker worktree owner
  shopt -s nullglob
  for marker in "$tasks_dir"/*/*.owner; do
    worktree=${marker%.owner}
    owner=$(cat "$marker")
    if [[ "$owner" == scheduled || -n "$(find "$marker" -mmin +1440)" ]]; then
      echo "Removing $owner backport environment $worktree"
      remove_environment "$worktree" || warn "could not remove $worktree"
    fi
  done
  shopt -u nullglob
  git -C "$FLINK_SOURCE_REPO" worktree prune
}

# A branch checked out in a worktree cannot be deleted; one outside prepare.sh's control gets a warning.
remove_branches() {
  local held branch worktree
  held=$(git -C "$FLINK_SOURCE_REPO" worktree list --porcelain \
    | awk '$1 == "worktree" { path = substr($0, 10) } $1 == "branch" { print $2 "\t" path }')
  git -C "$FLINK_SOURCE_REPO" for-each-ref --format='%(refname)' refs/heads/backport/ | while read -r branch; do
    worktree=$(awk -F '\t' -v ref="$branch" '$1 == ref { print $2; exit }' <<< "$held")
    if [[ -z "$worktree" ]]; then
      git -C "$FLINK_SOURCE_REPO" branch -q -D "${branch#refs/heads/}" || warn "could not delete ${branch#refs/heads/}"
    elif [[ ! -f "$worktree.owner" ]]; then
      warn "keeping ${branch#refs/heads/}: checked out in $worktree, which prepare.sh did not create"
    fi
  done
}

remove_environments
remove_branches
