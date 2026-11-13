#!/usr/bin/env bash
# Usage: diff_archive_entries.sh <previous-archive> <rc-archive> <previous-x.y.z> <x.y.z>
# Lists the entries of two archives (.tgz, .tar.gz, .whl, .jar, .zip), replaces each version
# string with <v>, and prints the differences. Exit 0: same; 1: differences to explain; other: error.

set -e

if [ "$#" -ne 4 ] || [ ! -f "$1" ] || [ ! -f "$2" ]; then
    echo 'Usage: diff_archive_entries.sh <previous-archive> <rc-archive> <previous-x.y.z> <x.y.z>' >&2
    exit 2
fi

list_entries() {
    case "$1" in
        *.tgz | *.tar.gz) tar -tzf "$1" ;;
        *.whl | *.jar | *.zip) unzip -Z1 "$1" ;;
        *) echo "Unsupported archive type: $1" >&2; return 2 ;;
    esac
}

# Fail on a listing error instead of diffing a truncated list.
previous_entries=$(list_entries "$1")
rc_entries=$(list_entries "$2")
diff -u --label "$3" --label "$4" \
    <(printf '%s\n' "$previous_entries" | sed "s/${3//./\\.}/<v>/g" | sort) \
    <(printf '%s\n' "$rc_entries" | sed "s/${4//./\\.}/<v>/g" | sort)
