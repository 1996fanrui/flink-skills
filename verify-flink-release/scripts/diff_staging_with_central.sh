#!/usr/bin/env bash
# Usage: diff_staging_with_central.sh <staging-repository-id> <x.y.z> <previous-x.y.z>
# Example: diff_staging_with_central.sh orgapacheflink-1948 1.20.6 1.20.5
# Compares the org.apache.flink artifactIds and the file names under each artifact version
# (sidecars excluded, version replaced with <v>) between a Nexus staging repository and the
# previous release on Maven Central. Exit 0: same; 1: differences to explain; other: error.
# The previous release is every artifact whose <previous-x.y.z> POM descends from flink-parent,
# so other projects sharing the groupId and version (such as Stateful Functions) are excluded.

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
mkdir previous-poms
xargs -P 16 -I{} bash -c '
    code=$(curl -sS -o "previous-poms/{}" --max-time 30 -w "%{http_code}" "$CENTRAL/{}/$OLD/{}-$OLD.pom")
    case "$code" in 200) ;; 404) rm "previous-poms/{}" ;; *) echo "HTTP $code for {}" >&2; exit 255 ;; esac
' < central-artifacts
# Record each POM as "<artifactId> <parent artifactId>", with "-" for a parent outside org.apache.flink.
for pom in previous-poms/*; do
    parent=$(sed -n '/<parent>/,/<\/parent>/{p;/<\/parent>/q}' "$pom")
    parent_artifact=-
    if [ "$(sed -n 's|.*<groupId>\(.*\)</groupId>.*|\1|p' <<< "$parent")" = org.apache.flink ]; then
        parent_artifact=$(sed -n 's|.*<artifactId>\(.*\)</artifactId>.*|\1|p' <<< "$parent")
    fi
    echo "${pom#previous-poms/} $parent_artifact"
done > previous-parents
# An artifact belongs to the previous release when its parent chain reaches flink-parent.
awk '{ parent[$1] = $2 } END {
    for (artifact in parent) {
        for (node = artifact; node != "flink-parent" && node in parent; ) node = parent[node]
        if (node == "flink-parent") print artifact
    }
}' previous-parents | sort > previous-artifacts

status=0
diff -u --label "Maven Central $OLD artifacts" --label "staging $V artifacts" \
    previous-artifacts staged-artifacts || status=1

sidecars='\.(md5|sha1|sha256|sha512|asc)$'
# Each parallel job writes its own file: jobs sharing one pipe interleave partial lines.
mkdir staged previous
xargs -P 16 -I{} bash -c 'set -o pipefail; staging_list "{}/$V/" | sed "s|^|{}/|" > "staged/{}" || exit 255' < staged-artifacts
xargs -P 16 -I{} bash -c 'set -o pipefail; central_list "{}/$OLD/" | sed "s|^|{}/|" > "previous/{}" || exit 255' < previous-artifacts
cat staged/* | grep -Ev "$sidecars" | sed "s/${V//./\\.}/<v>/g" | sort > staged-files
cat previous/* | grep -Ev "$sidecars" | sed "s/${OLD//./\\.}/<v>/g" | sort > previous-files
diff -u --label "Maven Central $OLD files" --label "staging $V files" \
    previous-files staged-files || status=1
exit "$status"
