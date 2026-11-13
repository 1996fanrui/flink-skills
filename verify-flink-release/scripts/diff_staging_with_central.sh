#!/usr/bin/env bash
# Usage: diff_staging_with_central.sh <staging-repository-id> <x.y.z> <previous-x.y.z>
# Example: diff_staging_with_central.sh orgapacheflink-1948 1.20.6 1.20.5
# Compares the org.apache.flink artifactIds and the file names under each artifact version
# (sidecars excluded, version replaced with <v>) between a Nexus staging repository and the
# previous release on Maven Central. Exit 0: same; 1: differences to explain; other: error.

set -eo pipefail

if [ "$#" -ne 3 ] || [[ ! "$1" =~ ^orgapacheflink-[0-9]+$ ]]; then
    echo 'Usage: diff_staging_with_central.sh <staging-repository-id> <x.y.z> <previous-x.y.z>' >&2
    exit 2
fi
for command_name in curl jq xargs mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing dependency: $command_name" >&2
        exit 2
    fi
done

export STAGING="https://repository.apache.org/service/local/repositories/$1/content/org/apache/flink"
export CENTRAL=https://repo1.maven.org/maven2/org/apache/flink
export V="$2" OLD="$3"
mkdir -p /tmp/agent-tmp
work_dir=$(mktemp -d /tmp/agent-tmp/flink-staging-diff.XXXXXXXX)
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"

# Each listing fails the script on an HTTP or parse error instead of yielding a short list.
staging_list() {
    curl -fsS --max-time 30 -H 'Accept: application/json' "$STAGING/$1" | jq -er '.data[].text'
}
central_list() {
    curl -fsS --max-time 30 "$CENTRAL/$1" | grep -oE 'href="[^"?/.][^"?]*"' | sed -E 's/^href="(.*)"$/\1/'
}
export -f staging_list central_list

staging_list '' | sort > staged-artifacts
central_list '' | sed -n 's|/$||p' > central-artifacts
# An artifact belongs to the previous release when its POM exists for that version.
xargs -P 16 -I{} bash -c '
    code=$(curl -sS -o /dev/null --max-time 30 -w "%{http_code}" "$CENTRAL/{}/$OLD/{}-$OLD.pom")
    case "$code" in 200) echo {} ;; 404) ;; *) echo "HTTP $code for {}" >&2; exit 255 ;; esac
' < central-artifacts | sort > previous-artifacts

status=0
diff -u --label "Maven Central $OLD artifacts" --label "staging $V artifacts" \
    previous-artifacts staged-artifacts || status=1

sidecars='\.(md5|sha1|sha256|sha512|asc)$'
xargs -P 16 -I{} bash -c 'staging_list "{}/$V/" | sed "s|^|{}/|" || exit 255' < staged-artifacts \
    | grep -Ev "$sidecars" | sed "s/${V//./\\.}/<v>/g" | sort > staged-files
xargs -P 16 -I{} bash -c 'central_list "{}/$OLD/" | sed "s|^|{}/|" || exit 255' < previous-artifacts \
    | grep -Ev "$sidecars" | sed "s/${OLD//./\\.}/<v>/g" | sort > previous-files
diff -u --label "Maven Central $OLD files" --label "staging $V files" \
    previous-files staged-files || status=1
exit "$status"
