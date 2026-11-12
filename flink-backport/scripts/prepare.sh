#!/usr/bin/env bash
# Prepare the worktree and private Maven repository for one Jira on one release branch.
#   bash <skill dir>/scripts/prepare.sh <FLINK-KEY> <release-X.Y>
# Prints WORKTREE=, MAVEN_REPO= and BRANCH= lines. Running it again reuses what exists.
# The owner is "scheduled" when FLINK_BACKPORT_SCHEDULED=1, otherwise "manual"; cleanup.sh relies on it.

set -e
set -o pipefail

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

key=$1
target=$2
[[ "$key" =~ ^FLINK-[0-9]+$ ]] || fail "expected a Jira key like FLINK-12345, got '$key'"
[[ "$target" =~ ^release-([0-9]+\.[0-9]+)$ ]] || fail "expected a branch like release-2.2, got '$target'"
version=${BASH_REMATCH[1]}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/env.sh
. "$script_dir/env.sh"

worktree="$HOME/flink-backport-workspaces/tasks/$key/$version"
repo="$worktree.m2"
marker="$worktree.owner"
branch="backport/$key-$version"
owner=manual
[[ "${FLINK_BACKPORT_SCHEDULED:-}" == 1 ]] && owner=scheduled

if [[ -f "$marker" && "$(cat "$marker")" != "$owner" ]]; then
  fail "$worktree is in use by a $(cat "$marker") run"
fi
mkdir -p "$(dirname "$worktree")"
# Written before anything else, so cleanup.sh also finds a half-prepared environment.
echo "$owner" > "$marker"

# The private repository keeps the shared ~/.m2 free of this branch's X.Y-SNAPSHOT artifacts,
# which other backports of the same branch would overwrite.
create_maven_repo() {
  local snapshot
  snapshot=$(awk '/<artifactId>flink-parent<\/artifactId>/ { found = 1; next }
    found && match($0, /<version>[^<]+<\/version>/) { print substr($0, RSTART + 9, RLENGTH - 19); exit }' "$worktree/pom.xml")
  [[ "$snapshot" == *-SNAPSHOT ]] || fail "cannot read the snapshot version from $worktree/pom.xml"
  rm -rf "$repo"
  if [[ -d "$HOME/.m2/repository" ]]; then
    # Hard links cost almost no disk; fall back to a real copy across file systems.
    cp -al "$HOME/.m2/repository" "$repo" 2>/dev/null || { rm -rf "$repo"; cp -a "$HOME/.m2/repository" "$repo"; }
  else
    mkdir -p "$repo"
  fi
  # Only snapshots built in this worktree may be used.
  if [[ -d "$repo/org/apache/flink" ]]; then
    find "$repo/org/apache/flink" -type d -name "$snapshot" -prune -exec rm -rf {} +
  fi
  # Maven may rewrite these in place, which would change the shared repository through a hard link.
  find "$repo" -type f \( -name 'maven-metadata*' -o -name '_remote.repositories' -o -name '*.lastUpdated' -o -name 'resolver-status.properties' \) \
    -exec sh -c 'for f; do cp -p "$f" "$f.new" && mv "$f.new" "$f"; done' sh {} +
}

if [[ -f "$worktree/.git" ]]; then
  current=$(git -C "$worktree" branch --show-current)
  [[ "$current" == "$branch" ]] || fail "$worktree is on '$current', expected $branch"
  [[ -d "$repo" ]] || create_maven_repo
else
  git -C "$FLINK_SOURCE_REPO" fetch --quiet "$upstream" "$target"
  git -C "$FLINK_SOURCE_REPO" worktree prune
  git -C "$FLINK_SOURCE_REPO" worktree add --quiet -B "$branch" "$worktree" "$upstream/$target"
  create_maven_repo
fi

printf 'WORKTREE=%s\nMAVEN_REPO=%s\nBRANCH=%s\n' "$worktree" "$repo" "$branch"
