# RC creation checklist

This is the fixed checklist for building one release candidate. For each release round, instantiate it in `3-rc-build-todo.md` ([progress documents](todo.md)): one block per version with its concrete paths, release commit, RC number, and a status per step. Before step 1, show the release manager that instance and wait for an explicit go; then run it without asking again, in step order except for the overlaps in [parallel execution](#parallel-execution), stopping only when a step's check fails. The agent runs every command. The release manager only types the GPG passphrase and performs actions that need their web login (see [permissions and credentials](#permissions-and-credentials) and [ATR integration](#atr-integration)).

Before running, read the target branch's `tools/releasing/` scripts: their environment variables, invocation directory, and rewritten version files differ across maintenance branches, and older guide examples are not the script contract. Differences observed for 1.20.6, 2.2.2, and 2.3.1:

- JDK: the `release` profile enforces Java `[1.8.0,1.8.1)` on 1.x, so build with JDK 8; on 2.x it enforces `[11.*,)`, so build with exactly JDK 11 (2.3.0-rc2 received a -1 vote for JDK 17-built artifacts).
- `create_release_branch.sh` on 2.3 and later also rewrites the REST API version in `docs/static/generated/*.yml`.
- `create_binary_release.sh` on 1.x builds Python packages in a conda environment created by `dev/lint-python.sh` with `python setup.py sdist`; on 2.x in a uv environment with `uv build`, which also produces the universal `apache_flink_libraries-<v>-py2.py3-none-any.whl`. Both expect exactly 12 platform wheels from CI in `flink-python/dist`.

## Placeholders

`<v>` target version `x.y.z`; `<x.y>` its maintenance line; `<N>` RC number; `<clone>` the version's standalone Flink clone ([workspace](workspace.md#one-standalone-clone-per-version)); `<rc>` the candidate's evidence directory `releases/<v>/rc<N>/`; `<jdk>` the branch's release JDK home; `<apache>` the remote name for `apache/flink`; `<fpr>` the signing key fingerprint; `<asf-id>` the release manager's Apache ID; `<profile-id>` the `org.apache.flink` Nexus staging profile ID; `<atr>` `https://releases.apache.org`; `<rc-commit>` step 3's commit; `<old>` the patch version this release supersedes on its line; `<rev>` the ATR revision holding this RC; `$JWT` an ATR API token ([API access](#api-access)); `<web-clone>` the version's standalone flink-web clone `releases/<v>/flink-web`; `<web-fork>` its remote name for the release manager's fork `<web-fork-repo>`, owned by `<web-fork-owner>`; `<date>` the announcement date `yyyy-mm-dd`. Maven steps run from `<clone>/tools` with `JAVA_HOME=<jdk> MVN=<clone>/mvnw`. Tee every script's output to `<rc>/logs/<step>.log`.

## Steps

| # | Step | Command or script (required environment) | Executor | Permissions and credentials | Directory and repository | Visibility and rollback | Output and check |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Preconditions | RM terminal: `export GPG_TTY=$(tty); echo test \| gpg --clearsign`. Agent: `echo test \| gpg --batch --pinentry-mode error --clearsign >/dev/null`; each RC row of [permissions and credentials](#permissions-and-credentials); `df -h <clone>` | RM types the passphrase; agent checks | GPG passphrase | any | Local | Agent check exits 0; if it fails, stop and ask the RM to retype the passphrase. `max-cache-ttl` counts from when it was typed, so the cache expires 8 h later even while in use: rerun the agent check before each later batch of signing steps, such as the next version of a round |
| 2 | Select the release commit | `git -C <clone> fetch <apache> release-<x.y>`; `git -C <clone> checkout --detach <apache>/release-<x.y>`; `gh run list -R apache/flink --workflow ci.yml --branch release-<x.y> --event push --limit 3 --json headSha,status,conclusion,url`; `git ls-remote <apache> 'refs/tags/release-<v>-rc*'`; `curl -sS --max-time 30 <atr>/api/release/get/flink/<v>` | Agent | Read only | `<clone>`, `<apache>` | Local | HEAD equals `<apache>/release-<x.y>`; its push CI run with the same `headSha` is recorded, finished or not: it gates the vote, not the build ([CI-baseline gate](todo.md#stage-gates)), so do not wait for it; clean `git status --porcelain`; `<N>` follows [RC numbering](#rc-numbering); the ATR release exists with `.release.phase` `release_candidate_draft` and `.release.download_path_suffix` `flink-<v>` ([ATR setup](#setup)); `test -d <clone>/.git` passes |
| 3 | Create the release branch | `cd <clone>/tools && JAVA_HOME=<jdk> MVN=<clone>/mvnw NEW_VERSION=<v> RELEASE_CANDIDATE=<N> releasing/create_release_branch.sh` | Agent | None | `<clone>/tools`; local branch `release-<v>-rc<N>` in `<clone>` | Local; undo with `git checkout --detach <commit> && git branch -D release-<v>-rc<N>` | Commit `Commit for release <v>` on the release commit; `git show --stat HEAD` covers the POMs (the root POM also carries japicmp), `docs/config.toml`, `pyflink/version.py`, and on 2.3+ `docs/static/generated/*.yml`; `git grep -l -- '-SNAPSHOT' -- '*pom.xml' docs/static/generated` lists only files that `git grep -l -- '-SNAPSHOT' release-<old> -- '*pom.xml' docs/static/generated` also lists (`flink-contrib` is outside the reactor). The clone is blob-less and `git grep` on a tag fetches each blob separately; one failed fetch kills it after it printed part of the list. So first fetch the tag's blobs in one batch, which must exit 0: `set -o pipefail; git ls-tree -r --format='%(objectname) %(path)' release-<old> \| awk '$2 ~ /pom\.xml$/ {print $1} $2 ~ /^docs\/static\/generated\// {print $1}' \| git -c fetch.negotiationAlgorithm=noop fetch --no-tags --no-write-fetch-head --filter=blob:none --stdin <apache>`; each `git grep` must exit 0 or 1 |
| 4 | Sign the tag locally | `git -C <clone> -c user.signingkey=<fpr> tag -s release-<v>-rc<N> -m "release-<v>-rc<N>"` | Agent | GPG cache | `<clone>` | Local until step 5; undo with `git tag -d` | `git verify-tag refs/tags/release-<v>-rc<N>` shows `<fpr>`; `git rev-parse refs/tags/release-<v>-rc<N>^{commit}` equals step 3's commit. The local branch and tag share one name, so always spell the tag `refs/tags/release-<v>-rc<N>` |
| 5 | Push the RC tag and start its Nightly | `git -C <clone> push <apache> refs/tags/release-<v>-rc<N>`; `gh workflow run nightly.yml -R apache/flink --ref refs/tags/release-<v>-rc<N>` ([5](#5-and-8-python-wheels)) | Agent | Committer push to and workflow dispatch on `apache/flink` | `<clone>`, `<apache>` | Public; delete the tag only when the RC is cancelled ([vote](vote.md)) | `git ls-remote <apache> 'refs/tags/release-<v>-rc<N>*'` peels to the RC commit; run ID recorded, its `headSha` equals the RC commit |
| 6 | Source release | `cd <clone>/tools && RELEASE_VERSION=<v> releasing/create_source_release.sh` | Agent | GPG cache | `<clone>/tools/releasing/release/` | Local; delete the directory to undo | `flink-<v>-src.tgz` with `.asc` and `.sha512`; `sha512sum -c`, `gpg --verify`; `verify-flink-release/scripts/check_source_archive.sh` passes |
| 7 | Stage Maven artifacts and close the staging repository | `cd <clone>/tools && JAVA_HOME=<jdk> MVN=<clone>/mvnw releasing/deploy_staging_jars.sh`; then close by REST ([7](#7-nexus-staging)) | Agent | Nexus user token in `~/.m2/settings.xml`; GPG cache | `<clone>`, `~/.m2` | Staging repository visible on repository.apache.org; undo by dropping it, also when the candidate is replaced (step 12) | Exactly one open repository from this deploy, containing `org/apache/flink/flink-core/<v>/`; after close, `type` is `closed` and no close rule failed; record its URL `https://repository.apache.org/content/repositories/orgapacheflink-<id>/`; `unzip -p ~/.m2/repository/org/apache/flink/flink-runtime/<v>/flink-runtime-<v>.jar .flink-runtime.version.properties` shows `git.commit.id=<rc-commit>`, not `${git.commit.id}` |
| 8 | Download the wheels | Wait for both `Build Python Wheels on ...` jobs, then download into `flink-python/dist` ([8](#5-and-8-python-wheels)) | Agent | Read access to `apache/flink` | `<rc>/wheels`, `<clone>/flink-python/dist` | Local | 12 files matching `apache_flink-<v>-*.whl`; `verify-flink-release/scripts/check_python_license_files.sh <clone>/flink-python/dist` passes; record run URL and artifact names |
| 9 | Binary release | `cd <clone>/tools && JAVA_HOME=<jdk> MVN=<clone>/mvnw RELEASE_VERSION=<v> releasing/create_binary_release.sh` | Agent | GPG cache | `<clone>/tools/releasing/release/` | Local | `flink-<v>-bin-scala_2.12.tgz` and `python/` with the sdists, 12 wheels (plus the libraries wheel on 2.x), each with `.asc` and `.sha512`; `sha512sum -c` and `gpg --verify` pass for every file; `verify-flink-release/scripts/check_python_license_files.sh <clone>/tools/releasing/release/python` passes for every sdist and wheel; `tar -xOzf flink-<v>-bin-scala_2.12.tgz flink-<v>/lib/flink-dist-<v>.jar > <rc>/flink-dist.jar && unzip -p <rc>/flink-dist.jar .flink-runtime.version.properties` shows `git.commit.id=<rc-commit>`; delete `<rc>/flink-dist.jar` afterwards |
| 10 | Upload to ATR and pass its checks | `rsync` the release output into the ATR release, record the RC commit, and read the checks ([10](#10-atr-upload-and-checks)) | Agent | ATR SSH key and `$JWT` | `<clone>/tools/releasing/release/`; ATR release `flink/<v>` | Public download URLs; a later upload replaces the files as a new revision | The revision's path listing matches the local inventory; zero `blocker` checks; every `concern` and `exception` reviewed; `<rev>` recorded |
| 11 | Website PR | Commit the announcement post with the confirmed [release notes](release-notes.md) and the download data, build, push to `<web-fork>`, then `gh pr create -R apache/flink-web` ([11](#11-website-pr)) | Agent | Push to the flink-web fork | `<web-clone>`, `<web-fork>` | Public PR; do not merge before finalization | PR URL recorded; links name `<v>` and the Jira release-notes version ID; the build check passes |
| 12 | Verify the RC | Right after step 5, invoke `verify-flink-release` in pre-vote mode with version, RC, tag commit, and `<rc>` as its report directory; hand it each later input as its step completes ([parallel execution](#parallel-execution)) | Agent | Read only | Verifier's own temporary directory; its [verification report](todo.md) in `<rc>` | Read only | The report shows overall `PASS` for this exact RC before `[VOTE]`; on `FAIL`, take every FAIL from the one verification pass, fix them all, and rebuild under the number that [RC numbering](#rc-numbering) gives |
| 13 | Clean build outputs | After step 12 passes: `git -C <clone> clean -ndX` to review, then `-fdX`; remove `<rc>/wheels` and the `~/.m2/repository/org/apache/flink/*/<v>` directories installed by step 7 | Agent | None | `<clone>`, `~/.m2` | Local, irreversible; keep `<rc>/logs` | `df -h` recorded; `<clone>` clean |

Record each step's result and evidence link in the round's `3-rc-build-todo.md` as it completes, and the RC identity (tag, commit, fingerprint, staging repository, ATR revision, wheel run, website PR) in `state.md`.

## Step commands

### 5 and 8: Python wheels

The PyFlink wheels come only from the `Build Python Wheels` jobs of the branch's `nightly.yml`. That workflow has only a `workflow_dispatch` trigger, so pushing the tag does not start it: dispatch it on the pushed RC tag. The same run's test jobs are this RC's pre-release full-test Nightly for the [CI-baseline gate](todo.md#stage-gates); triage them with [CI triage](ci-triage.md).

```bash
timeout 30 gh run list -R apache/flink --workflow nightly.yml --branch release-<v>-rc<N> --limit 1 --json databaseId,headSha,status
timeout 30 gh run view <run-id> -R apache/flink --json jobs \
  --jq '.jobs[] | select(.name | startswith("Build Python Wheels")) | [.name, .status, .conclusion] | @tsv'
timeout 30 gh api "repos/apache/flink/actions/runs/<run-id>/artifacts?per_page=100" \
  --jq '.artifacts[] | select(.name | startswith("wheel_")) | [.id, .name, .workflow_run.head_sha] | @tsv'
# for each <artifact-id> <name>; head_sha must be the RC commit
mkdir -p <rc>/wheels/<name>
timeout 600 gh api repos/apache/flink/actions/artifacts/<artifact-id>/zip > <rc>/wheels/<name>.zip
unzip -q -d <rc>/wheels/<name> <rc>/wheels/<name>.zip && rm <rc>/wheels/<name>.zip
mkdir -p <clone>/flink-python/dist
find <rc>/wheels -name 'apache_flink-<v>-*.whl' -exec cp {} <clone>/flink-python/dist/ \;
ls <clone>/flink-python/dist/*.whl | wc -l   # must be 12
timeout 120 verify-flink-release/scripts/check_python_license_files.sh <clone>/flink-python/dist   # LICENSE and NOTICE in every wheel
```

Download by artifact ID rather than with `gh run download -p` or `-n`: gh 2.45 resolves those names by paging every artifact of the repository, which on `apache/flink` fails with HTTP 500 partway through.

### 7: Nexus staging

Implicit staging puts every deploy with the same user, IP address, and Maven user agent into one open staging repository, so identify it before closing. Read the token from `~/.m2/settings.xml` without printing it:

```bash
NEXUS_CRED=$(uv run --no-project python -I -c "import os,xml.etree.ElementTree as E; s=next(x for x in E.parse(os.path.expanduser('~/.m2/settings.xml')).getroot().iter('server') if x.findtext('id')=='apache.releases.https'); print(s.findtext('username')+':'+s.findtext('password'))")
NX=https://repository.apache.org/service/local
timeout 60 curl -sS --max-time 60 -u "$NEXUS_CRED" -H 'Accept: application/json' "$NX/staging/profiles" \
  | jq -r '.data[] | select(.name == "org.apache.flink") | .id'                       # <profile-id>
timeout 60 curl -sS --max-time 60 -u "$NEXUS_CRED" -H 'Accept: application/json' "$NX/staging/profile_repositories/<profile-id>" \
  | jq -r '.data[] | select(.type == "open" and .userId == "<asf-id>") | [.repositoryId, .userAgent, .createdDate] | @tsv'
timeout 60 curl -sS --max-time 60 -u "$NEXUS_CRED" -X POST -H 'Content-Type: application/json' "$NX/staging/profiles/<profile-id>/finish" \
  -d '{"data":{"stagedRepositoryId":"<repository-id>","description":"Apache Flink, version <v>, release candidate <N>"}}'
timeout 60 curl -sS --max-time 60 -u "$NEXUS_CRED" -H 'Accept: application/json' "$NX/staging/repository/<repository-id>/activity" \
  | jq -r '.[] | .name as $n | .events[] | [$n, .name] | @tsv'                           # no ruleFailed
```

`/finish` closes and `/drop` (same body) drops a repository, per the ASF Nexus staging REST documentation. If the open list does not have exactly one entry, stop. The Nexus web UI (Staging Repositories → Close) is the equivalent manual path.

### 10: ATR upload and checks

Upload with `rsync` over SSH. The web and API uploads are limited to 512 MiB per request, and a 2.x binary archive is about 605 MB. ATR's rsync accepts only `-av` and `--delete`, keeps subdirectories such as `python/`, and stores each upload as a new revision; `--delete` makes the release hold exactly this RC's files, also when the upload replaces an earlier RC. Recording the commit creates another revision, so read `<rev>` after it.

```bash
timeout 3600 rsync -av --delete -e 'ssh -p 2222' <clone>/tools/releasing/release/ <asf-id>@releases.apache.org:/flink/<v>/
timeout 30 curl -sS --max-time 30 -X POST -H "Authorization: Bearer $JWT" -H 'Content-Type: application/json' \
  <atr>/api/release/commit -d '{"project":"flink","version":"<v>","commit":"<rc-commit>"}'
timeout 30 curl -sS --max-time 30 <atr>/api/release/get/flink/<v> | jq -r .release.latest_revision_number    # <rev>
timeout 30 curl -sS --max-time 30 "<atr>/api/release/paths/flink/<v>/<rev>?limit=1000" | jq -r '.count, .rel_paths[]'
timeout 30 curl -sS --max-time 30 <atr>/api/checks/ongoing/flink/<v>/<rev> | jq .ongoing                       # repeat until 0
total=$(timeout 60 curl -sS --max-time 60 "<atr>/api/checks/list/flink/<v>/<rev>?limit=1" | jq .count)
for o in $(seq 0 1000 $((total - 1))); do
  timeout 60 curl -sS --max-time 60 "<atr>/api/checks/list/flink/<v>/<rev>?offset=$o&limit=1000" | jq -c '.checks[]'
done > <rc>/atr-checks.jsonl
wc -l < <rc>/atr-checks.jsonl                                                                          # must equal $total
jq -r '[.status, .checker] | @tsv' <rc>/atr-checks.jsonl | sort | uniq -c
jq -r 'select(.status | IN("blocker", "concern", "exception")) | [.status, .checker, .primary_rel_path, .member_rel_path, .message] | @tsv' <rc>/atr-checks.jsonl
```

`checks/list` returns at most 1000 rows per request, and a Flink RC produces about 16,500, so page with `offset` and `limit`; `count` is the total.

The path listing must equal `find . -type f | sed 's|^\./||' | sort` run in the release output directory, with `count` equal to the number of listed paths. A `blocker` cannot be ignored and stops the vote from starting: fix its cause and rebuild under `<N>+1`. Review each `concern` and `exception`; concerns do not block, but the vote must acknowledge each reviewed checker name in `concerns_noted` at [vote start](vote.md). The first Flink run (1.20.6-rc1) gave:

- One blocker from `license.files`: the `apache_flink` PyFlink sdist, and its wheels, have lacked a NOTICE file since 1.13 (FLINK-41467). ATR classifies an sdist as a source archive and requires a root NOTICE, so the vote cannot start until the release commit contains the fix.
- About 380 concerns, because Flink's RAT exclusions live in the root POM, which ATR does not read: about 234 from `license.headers`, including Cython-generated `*_fast.c` files, and about 146 from `rat.check`, mostly "Unknown license", with 4 "Unapproved" where bundled license texts are misread as GPL. Compare each against the POM's exclusions and the bundled licenses.
- Three suggestions for the missing SBOM.

### 11: Website PR

The branch depends only on the confirmed release notes, so it can be prepared before the RC is built; the PR opens at this step. Clone the current site branch (about 380 MB with the Hugo theme submodule), then add the `<web-fork>` remote:

```bash
timeout 900 git clone --filter=blob:none --single-branch --branch asf-site https://github.com/apache/flink-web.git <web-clone>
timeout 60 git -C <web-clone> switch -c release-<v>
timeout 300 git -C <web-clone> submodule update --init --recursive
```

Change only `docs/` sources, as past patch PRs do; generated `content/` follows the publication path in [finalization](finalization.md):

- `docs/content/posts/<date>-release-<v>.md`: front matter `title: "Apache Flink <v> Release Announcement"`, `date: "<date>T00:00:00.000Z"`, alias `/news/<yyyy>/<mm>/<dd>/release-<v>.html`, and the release manager under `authors`; the body follows [release notes](release-notes.md), with the `# Release Artifacts` section taken from the line's previous patch post and its version replaced.
- `docs/data/flink.yml`: in the `<x.y>:` block, replace the previous patch version with `<v>` everywhere; keep other keys such as `release_notes_url`.
- `docs/data/release_archive.yml`: insert `version_short: "<x.y>"`, `version_long: <v>`, `release_date: <date>` directly above the previous patch of the same line. The file is grouped by line, newest line first, and the downloads page renders it in file order.
- `docs/config.toml`: only when `<x.y>` equals `FlinkStableShortVersion`, set `FlinkStableVersion = "<v>"`.

The vote result is unknown when the branch is prepared, so `<date>` starts as an estimate; before merging, set the file name, `date`, alias, and `release_date` to the actual announcement date. Hugo skips posts dated in the future, so a post merged with a later date stays off the site until that day (the 2.3.0 post needed a follow-up fix).

Build check, with the Hugo version from `REQUIRED_HUGO_VERSION` in `build.sh` (the image takes about 1 GB of disk):

```bash
out=$(mktemp -d /tmp/agent-tmp/flink-web-build.XXXXXXXX); chmod 777 "$out"
timeout 300 docker run --rm -u "$(id -u):$(id -g)" -v <web-clone>/docs:/src -v "$out":/out jakejarvis/hugo-extended:<hugo-version> --buildFuture --destination /out
grep -c 'flink-<v>-bin-scala_2.12.tgz' "$out"/downloads/index.html              # 1
ls "$out"/<yyyy>/<mm>/<dd>/apache-flink-<v>-release-announcement/index.html
rm -rf "$out"
```

Push `release-<v>` to `<web-fork>`; open the PR only after the release manager confirms the [release notes](release-notes.md#release-manager-review). Use the title of past patch PRs, `Add Flink <v> release`, and a body file that names the RC tag under vote, lists each changed `docs/` file, states that `<date>` is a placeholder to be set to the actual announcement date before merging, and asks not to merge before the vote passes and the release is published:

```bash
timeout 60 gh pr create -R apache/flink-web --base asf-site --head <web-fork-owner>:release-<v> --title "Add Flink <v> release" --body-file <body-file>
```

## Directories and repositories

| Item | Location | Purpose |
| --- | --- | --- |
| Version clone | `releases/<v>/flink` | Standalone blob-less clone of `release-<x.y>` with its own `.git` directory; detached at the release commit, then on `release-<v>-rc<N>`; every script runs from its `tools/` |
| `<apache>` remote | `apache/flink` | Fetch the maintenance branch; push only the RC tag (committer SSH) and dispatch `nightly.yml` on it |
| flink-web clone | `releases/<v>/flink-web` | Standalone blob-less clone of `asf-site` with the `<web-fork>` remote; branch `release-<v>` for the website PR |
| RC evidence | `releases/<v>/rc<N>/` | Logs, downloaded wheels, inventory, verification report |
| Build output | `<clone>/tools/releasing/release/` | Source, binary, and `python/` artifacts before upload |
| ATR release | `<asf-id>@releases.apache.org:/flink/<v>/` (SSH port 2222) | Step 10's `rsync` target; one release per version, one revision per upload |
| Maven local repository | `~/.m2/repository` | Shared by all version clones; step 7 installs the version's artifacts here |
| Maven settings | `~/.m2/settings.xml` (mode 600) | Nexus token for servers `apache.releases.https` and `apache.snapshots.https` |
| GnuPG home | `~/.gnupg` | Signing key and `gpg-agent.conf` |

Record the concrete paths and remote names in the workspace's `workspace.md`, not in this skill.

## Permissions and credentials

| Item | Needed by | How to obtain | How to verify |
| --- | --- | --- | --- |
| Signing key in `KEYS`, ATR, and id.apache.org | Steps 1, 4, 6, 7, 9, 10 | See [signing key](#signing-key) | `curl -s https://dist.apache.org/repos/dist/release/flink/KEYS \| gpg --show-keys --with-colons \| grep -c <fpr>` is nonzero; `curl -s <atr>/api/committee/keys/flink \| jq -r '.keys[].fingerprint'` lists `<fpr>` in lowercase; `https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x<fpr>` and `https://keys.openpgp.org/vks/v1/by-fingerprint/<fpr>` return 200 |
| GPG passphrase cache | Same | `gpg-agent.conf` with `default-cache-ttl 28800`, `max-cache-ttl 28800`, `pinentry-program /usr/bin/pinentry-curses`, then `gpgconf --reload gpg-agent`; the RM caches the passphrase in step 1 | Step 1's non-interactive check |
| Nexus user token | Step 7 | RM logs in to repository.apache.org → Profile → User Token → Access User Token; the agent writes it into both servers of `~/.m2/settings.xml` | `GET $NX/staging/profiles` returns 200 and lists `org.apache.flink`; a wrong password returns 401 |
| ATR account, SSH key, and token | Steps 2, 10; vote; finalization | [ATR setup](#setup) | `GET <atr>/api/user/info` with `$JWT` returns the RM's ID; `GET <atr>/api/ssh-keys/list/<asf-id>` lists the local public key; `ssh-keygen -F '[releases.apache.org]:2222'` finds the host key; an invalid token returns 401 |
| ATR release per version | Steps 2, 10 | [ATR setup](#setup) | Step 2's check |
| Push to and dispatch on `apache/flink` | Step 5 | ASF committer with linked GitHub account and SSH key | `gh api repos/apache/flink --jq .permissions.push` is `true` |
| flink-web fork | Step 11 | RM's `flink-web` fork | `gh api repos/<web-fork-repo> --jq .permissions.push` is `true` |
| PyPI maintainer and API token | Finalization only | An existing owner adds the RM's own PyPI account as Maintainer of `apache-flink` and `apache-flink-libraries`; the RM creates an API token. Request early | The RM sees both projects under "Your projects" |
| PyPI quota | Before step 9 | Request an increase in a public pypi/support issue if needed; approval can take days | Used size: `curl -s https://pypi.org/pypi/<project>/json \| jq '[.releases[][].size] \| add'`; limit: the latest public pypi/support quota issue for that project; remaining space must exceed this round's `python/` size per project. No shared-account login is needed |
| Jira release permission | Finalization only | Flink PMC membership | `GET https://issues.apache.org/jira/rest/api/2/mypermissions?projectKey=FLINK&permissions=ADMINISTER_PROJECTS` with the RM's token shows `havePermission: true`; anonymous read access proves nothing |

### Signing key

Use an RSA 4096 key with sign and certify capability ([SC]) under the RM's Apache address. If the old key's private part is lost, do not renew it: generate a new key on the build host, append it to `KEYS` and keep every old key there (`svn co https://dist.apache.org/repos/dist/release/flink`, `(gpg --list-sigs <fpr> && gpg --armor --export <fpr>) >> KEYS`, `svn ci`), and upload it to `keyserver.ubuntu.com` (`gpg --keyserver hkps://keyserver.ubuntu.com --send-keys <fpr>`) and to keys.openpgp.org through its VKS API (`POST https://keys.openpgp.org/vks/v1/upload` with the armored key, then `POST https://keys.openpgp.org/vks/v1/request-verify` with the returned token and the address). The RM then clicks the keys.openpgp.org verification mail and adds the fingerprint at id.apache.org. ATR checks signatures against its own key store, which it syncs from the committee's SVN `KEYS`; if the key is not listed there yet, add it with `POST <atr>/api/key/add` (`{"asfuid":"<asf-id>","key":"<armored public key>","committees":["flink"]}`, Bearer `$JWT`). `people.apache.org/keys` is regenerated daily from LDAP; waiting for it does not block the RC. An off-host backup of the private key is the RM's choice. Set the key as `user.signingkey` in each version clone.

## ATR integration

Apache Trusted Releases (ATR, `<atr>`) carries each candidate from upload through vote to dist/release. Once a project uses ATR, a direct SVN commit to dist/release raises an "Unmanaged release" alert to private@, so every version of a round goes through ATR; SVN remains only for `KEYS`. Nexus staging and release, the PyPI upload, Git tags, Jira, Docker, and the website stay outside ATR. With an email vote, ATR's API covers only the agent rows below; resolving the vote, publishing, and announcing are web-only release manager actions.

| Release action | ATR interface | Executor | Details |
| --- | --- | --- | --- |
| Stage RC files and run checks | `rsync`, `POST /api/release/commit`, `GET /api/checks/list` | Agent | [Step 10](#10-atr-upload-and-checks) |
| Send `[VOTE]` | `POST /api/vote/start` | Agent | [Vote](vote.md) |
| Tally votes | `POST /api/vote/tabulate` | Agent, cross-checked with the thread | [Vote](vote.md) |
| Close the vote and send `[RESULT]` | Web `/resolve/flink/<v>` | RM | [Vote](vote.md) |
| Publish to dist/release | Web `/finish/flink/<v>` | RM | [Finalization](finalization.md) |
| Record Maven Central and PyPI | `POST /api/distribution/record` | Agent | [Finalization](finalization.md) |
| Announce and archive the superseded release | Web `/announce/flink/<v>` and `/file/flink/<old>` | RM | [Follow-up](follow-up.md) |

### Setup

Once, the RM logs in to `<atr>` with their Apache account and MFA, then:

- creates a personal access token at `<atr>/tokens` (valid 180 days) and saves it in a mode-600 file `<pat-file>`, whose path the agent records in `workspace.md`;
- adds the build host's SSH public key at `<atr>/keys/ssh/add`, the only place keys can be added.

Before the first `rsync`, the agent adds ATR's host key: `ssh-keyscan -p 2222 releases.apache.org > <scan-file>`, prints its fingerprint with `ssh-keygen -lf <scan-file>`, records the fingerprint in `workspace.md`, and appends the file to `~/.ssh/known_hosts`. On a host without IPv6 connectivity to releases.apache.org, add `-4` to every `ssh-keyscan`, `curl`, and `ssh` call to ATR (`rsync -e 'ssh -4 -p 2222'`), and record that in `workspace.md`.

Each round, before step 2, the RM creates every version's release at `<atr>/start/flink` with version `<v>` and download path suffix `flink-<v>`, not expedited. An `rsync` to a missing release creates it automatically but cannot set the suffix or archive options.

### API access

```bash
JWT=$(timeout 30 curl -sS --max-time 30 -X POST -H 'Content-Type: application/json' <atr>/api/jwt/create \
  -d "$(jq -n --arg u <asf-id> --rawfile p <pat-file> '{asfuid: $u, pat: ($p | rtrimstr("\n"))}')" | jq -r .jwt)
timeout 30 curl -sS --max-time 30 -H "Authorization: Bearer $JWT" <atr>/api/user/info
```

A JWT lasts 30 minutes, and `jwt/create` is rate limited (at most 10 per PAT per hour, then HTTP 429): save the JWT in a mode-600 file outside the workspace and reuse it until it expires, instead of creating one per call. Never print the PAT or JWT.

## Parallel execution

Steps run in numbered order except for these overlaps within one version:

- **Tag push and Nightly with the build:** push the tag and start its Nightly (step 5) alongside the source release (step 6) and the Nexus deploy (step 7). The Nightly runs for hours, and its wheels are needed only at step 8.
- **Verification with the later build steps:** each `verify-flink-release` check group starts as soon as its own inputs exist, in parallel with the remaining build steps; do not wait for the whole build or the ATR upload. Hand the verifier each input when its step completes:

  | After step | Input | Check groups that start |
  | --- | --- | --- |
  | 5, tag pushed | Tag and commit | Tag; changes, release notes, and CI |
  | 6, source release created | Source archive | Full source build first, as the long pole; then the source archive |
  | 7, staging repository closed | Staging repository URL | Nexus diff and the staged commit-ID check |
  | 8, wheels downloaded | Wheels and their Nightly run URL | Wheels |
  | 9, binary release created | Binary archive and `python/` | Binary diff, Python packages diff, PyFlink installation, cluster smoke test |
  | 10, ATR upload done | ATR release and `<rev>` | ATR revision and its checks |
  | 11, website PR opened | PR URL | Website |

  The verifier assembles the single report once every group has finished, as its `references/report.md` describes; step 12's result is that report.
- **Website PR and vote draft with the build:** the website branch needs only the confirmed release notes and the PR only the RC tag's name, so run step 11 during steps 6 to 10. Draft the `[VOTE]` mail during the build too, filling in each item as its step records it ([vote](vote.md)).

### Across versions

Only the Nexus deploy (step 7) and the binary build (step 9) run one version at a time. For every later version, create the RC branch and signed tag, push the tag, and start its Nightly (steps 1–5) right away, in parallel with the earlier version's Nexus deploy, so its wheels are ready when its turn comes. Steps 7 and 9 are serial because:

- **Nexus staging**: implicit staging groups deploys by user, IP address, and user agent, and Maven 3.8.6 sends `Apache-Maven/<version> (Java <java.version>; <os>)`, so two versions deployed with the same JDK land in one open repository. Close each version's repository before the next deploy.
- **Maven local repository**: the version clones share `~/.m2/repository`, and the branches' Maven 3.8.6 wrapper bundles maven-resolver 1.6.3 without the named file locks that let concurrent processes share it.
- **Disk**: before each version's step 7 and step 9, measure with `du -sh releases/*/ ~/.m2/repository/org/apache/flink` and `df -h` instead of estimating from earlier releases, and free an earlier version with step 13 if space is short.

## RC numbering

One `release-<v>-rc<N>` names exactly one tag and commit, so a number never mixes artifacts from two commits.

- **New number**: whenever the RC tag or its commit would change (the branch HEAD moved, a source fix, a new tag), or once the candidate was published (its staging repository closed and announced, its ATR vote started, or its vote mail sent). Take a number above every RC number of `<v>` in `state.md` and in the remote tags, since a cancelled RC's tag may be deleted. Never reuse the old number in these cases, even if its candidate was never published; keep or delete its local branch and tag.
- **Same number**: allowed only when the tag and its commit stay exactly the same, the branch HEAD has not moved, and nothing was published, such as a build aborted for a build-environment reason. Rerun steps 1 and 2 as checks, skip steps 3 to 5, clear the aborted build's outputs, and redo the local build from step 6 on a checkout of `refs/tags/release-<v>-rc<N>`; artifacts already produced from that tag, such as step 5's Nightly wheels, stay valid.

In both cases, drop every open or closed Nexus staging repository of the replaced build before deploying again.

## Quality while building

- Bind one `<v>-rc<N>` to its signed tag, commit, signing fingerprint and `KEYS`, source and binary files, ASC/SHA512, Nexus staging repository, Python files under `python/`, website PR, and corresponding CI runs. Confirm each wheel traces to this RC commit and check the branch-specific platform matrix separately from any `apache-flink-libraries` universal wheel. Use a different wheel build path only if its full matrix and provenance have been verified. Record each item's origin, hash, and upload result. Check Docker publishing readiness and access now; Docker images are finalized after the official release is available, not a required RC artifact.
- Before a replacement RC, preserve the prior RC's evidence, clear its build outputs, and restart from step 2; never derive a new RC from the old RC commit by accident.
- Apply the installed `verify-flink-release` skill's quality checks while producing each package, CI artifact, and website PR: packaging, signing, license and notice coverage, provenance, build and runtime behavior, and version consistency. Investigate failures at their cause; do not continue with an apparently complete RC.
