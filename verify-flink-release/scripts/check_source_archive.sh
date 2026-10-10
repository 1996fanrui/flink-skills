#!/usr/bin/env bash
# Usage: check_source_archive.sh <flink-source-archive.tgz>
# Checks archive integrity, safe extraction paths, root license files, and macOS debris.

set -e

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo 'Usage: check_source_archive.sh <flink-source-archive.tgz>' >&2
    exit 2
fi
for command_name in tar uv; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing dependency: $command_name" >&2
        exit 2
    fi
done

tar -tzf "$1" > /dev/null
uv run --no-project python - "$1" <<'PY'
import sys
import tarfile

archive = sys.argv[1]
roots = set()
license_roots = set()
notice_roots = set()
seen = set()
entry_types = {}

with tarfile.open(archive, "r:gz") as source:
    for member in source:
        name = member.name
        parts = [part for part in name.split("/") if part != "."]
        if (name.startswith("/") or not parts or
                any(part in ("", "..") for part in parts)):
            raise SystemExit(f"Unsafe source archive path: {name}")
        if member.issym() or member.islnk() or not (member.isfile() or member.isdir()):
            raise SystemExit(f"Unsafe source archive entry type: {name}")
        normalized = "/".join(parts)
        if normalized in seen:
            raise SystemExit(f"Duplicate source archive path: {name}")
        seen.add(normalized)
        entry_types[normalized] = "directory" if member.isdir() else "file"
        roots.add(parts[0])
        if len(parts) == 2 and member.isfile():
            if parts[1] == "LICENSE":
                license_roots.add(parts[0])
            elif parts[1] == "NOTICE":
                notice_roots.add(parts[0])
        if any(part.startswith("._") or part in ("__MACOSX", ".DS_Store") for part in parts):
            raise SystemExit(f"Source archive contains macOS metadata: {name}")

for name in entry_types:
    parents = name.split("/")[:-1]
    for length in range(1, len(parents) + 1):
        parent = "/".join(parents[:length])
        if parent in entry_types and entry_types[parent] != "directory":
            raise SystemExit(f"Source archive file blocks a directory: {parent}")

if len(roots) != 1:
    raise SystemExit("Source archive must contain one top-level directory")
if license_roots != roots:
    raise SystemExit("Source archive has no top-level LICENSE")
if notice_roots != roots:
    raise SystemExit("Source archive has no top-level NOTICE")
PY

echo 'PASS source archive structure'
