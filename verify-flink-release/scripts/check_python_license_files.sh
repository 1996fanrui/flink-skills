#!/usr/bin/env bash
# Usage: check_python_license_files.sh <directory>
# Checks that every PyFlink sdist (*.tar.gz) and wheel (*.whl) under <directory> ships LICENSE and NOTICE:
# an sdist in its top-level directory, a wheel in *.dist-info/ or *.dist-info/licenses/.

set -e

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    echo 'Usage: check_python_license_files.sh <directory>' >&2
    exit 2
fi
if ! command -v uv >/dev/null 2>&1; then
    echo 'Missing dependency: uv' >&2
    exit 2
fi

uv run --no-project python -I - "$1" <<'PY'
import pathlib
import re
import sys
import tarfile
import zipfile

REQUIRED = {"LICENSE", "NOTICE"}
WHEEL_LICENSE = re.compile(r"^[^/]+\.dist-info/(?:licenses/)?(LICENSE|NOTICE)$")

packages = sorted(
    p for p in pathlib.Path(sys.argv[1]).rglob("*") if p.is_file() and p.name.endswith((".tar.gz", ".whl"))
)
if not packages:
    raise SystemExit("No Python sdist or wheel found")

failed = False
for package in packages:
    if package.name.endswith(".whl"):
        with zipfile.ZipFile(package) as archive:
            found = {m.group(1) for m in map(WHEEL_LICENSE.match, archive.namelist()) if m}
    else:
        with tarfile.open(package, "r:gz") as archive:
            found = {
                parts[1]
                for parts in (member.name.split("/") for member in archive.getmembers() if member.isfile())
                if len(parts) == 2 and parts[1] in REQUIRED
            }
    missing = sorted(REQUIRED - found)
    if missing:
        failed = True
        print(f"FAIL {package.name}: missing {', '.join(missing)}")
    else:
        print(f"PASS {package.name}")

if failed:
    raise SystemExit("Python packages without LICENSE and NOTICE found")
PY
