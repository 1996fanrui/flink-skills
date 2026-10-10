#!/usr/bin/env bash
# Usage: check_rc_artifacts.sh <local-rc-directory> <local-asf-KEYS-file> <x.y.z> <rcN> <remote-artifact-manifest>
# The manifest contains one RC-root-relative artifact path per line, including python/.
# Sidecars are excluded from the manifest but required beside every artifact.

set -e

if [ "$#" -ne 5 ] || [ ! -d "$1" ] || [ ! -f "$2" ] || [ ! -f "$5" ]; then
    echo 'Usage: check_rc_artifacts.sh <local-rc-directory> <local-asf-KEYS-file> <x.y.z> <rcN> <remote-artifact-manifest>' >&2
    exit 2
fi

if [[ ! "$3" =~ ^[0-9]+\.[0-9]+\.[1-9][0-9]*$ ]] || [[ ! "$4" =~ ^rc[0-9]+$ ]]; then
    echo 'Expected a patch version and numbered release candidate' >&2
    exit 2
fi
if [ "$(basename "${1%/}")" != "flink-$3-$4" ]; then
    echo "RC directory must be named flink-$3-$4" >&2
    exit 1
fi

for command_name in gpg sha512sum grep mktemp wc basename sort diff find head tail; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing dependency: $command_name" >&2
        exit 2
    fi
done

mkdir -p /tmp/agent-tmp
verification_dir=$(mktemp -d /tmp/agent-tmp/flink-rc-verification.XXXXXXXX)
trap 'rm -rf "$verification_dir"' EXIT
gpg --homedir "$verification_dir" --batch --import "$2" >/dev/null 2>&1

if [ ! -s "$5" ] || grep -Ev '^[A-Za-z0-9._+-]+(/[A-Za-z0-9._+-]+)*$' "$5" >/dev/null; then
    echo 'Remote artifact manifest is empty or contains invalid relative paths' >&2
    exit 1
fi
if [ -n "$(tail -c 1 "$5")" ]; then
    echo 'Remote artifact manifest must end with a newline' >&2
    exit 1
fi
while IFS= read -r relative_path; do
    IFS='/' read -r -a path_components <<< "$relative_path"
    for component in "${path_components[@]}"; do
        if [ "$component" = . ] || [ "$component" = .. ]; then
            echo "Remote artifact manifest contains path traversal: $relative_path" >&2
            exit 1
        fi
    done
done < "$5"
if grep -E '(^|/)KEYS$|\.asc$|\.sha512$' "$5" >/dev/null; then
    echo 'Remote artifact manifest contains sidecar or KEYS entries' >&2
    exit 1
fi
if ! grep -Fx "flink-$3-src.tgz" "$5" >/dev/null; then
    echo 'Remote artifact manifest has no Flink source archive' >&2
    exit 1
fi
sort "$5" > "$verification_dir/artifacts"
if [ "$(wc -l < "$5")" -ne "$(sort -u "$5" | wc -l)" ]; then
    echo 'Remote artifact manifest contains duplicate entries' >&2
    exit 1
fi
while IFS= read -r relative_path; do
    printf '%s\n%s.asc\n%s.sha512\n' "$relative_path" "$relative_path" "$relative_path"
done < "$verification_dir/artifacts" | sort > "$verification_dir/expected"
if [ -n "$(find "$1" ! -type f ! -type d -print -quit)" ]; then
    echo 'Local RC directory contains an unsupported entry type' >&2
    exit 1
fi
rc_dir=${1%/}
find "$rc_dir" -type f -print | while IFS= read -r listed_file; do
    printf '%s\n' "${listed_file#"$rc_dir"/}"
done | sort > "$verification_dir/actual"
if ! diff -u "$verification_dir/expected" "$verification_dir/actual"; then
    echo 'Local files differ from the complete remote RC manifest and required sidecars' >&2
    exit 1
fi

artifact_count=0
while IFS= read -r relative_path; do
    artifact="$rc_dir/$relative_path"
    artifact_count=$((artifact_count + 1))
    checksum_line=$(< "$artifact.sha512")
    if [[ ! "$checksum_line" =~ ^([[:xdigit:]]{128})[[:space:]][\ *](.+)$ ]]; then
        echo "Invalid SHA512 checksum record in $artifact.sha512" >&2
        exit 1
    fi
    expected_digest=${BASH_REMATCH[1]}
    checksum_name=${BASH_REMATCH[2]}
    if [ "$checksum_name" != "${artifact##*/}" ] && [ "$checksum_name" != "$relative_path" ]; then
        echo "SHA512 checksum names the wrong artifact: $artifact.sha512" >&2
        exit 1
    fi
    actual_digest=$(sha512sum "$artifact")
    actual_digest=${actual_digest%% *}
    if [ "${expected_digest,,}" != "${actual_digest,,}" ]; then
        echo "SHA512 mismatch for $artifact" >&2
        exit 1
    fi
    if [ "$(head -n 1 "$artifact.asc")" != '-----BEGIN PGP SIGNATURE-----' ] ||
        [ "$(tail -n 1 "$artifact.asc")" != '-----END PGP SIGNATURE-----' ]; then
        echo "Signature is not ASCII-armored: $artifact.asc" >&2
        exit 1
    fi
    if ! gpg --homedir "$verification_dir" --batch --verify "$artifact.asc" "$artifact" >/dev/null 2>&1; then
        echo "Signature verification failed for $artifact" >&2
        exit 1
    fi
    echo "PASS $relative_path"
done < "$verification_dir/artifacts"

if [ "$artifact_count" -eq 0 ]; then
    echo 'No release artifacts found' >&2
    exit 1
fi
