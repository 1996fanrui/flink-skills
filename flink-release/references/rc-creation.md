# RC creation checklist

This is the fixed checklist for building one release candidate. For each release round, instantiate it in `3-rc-build-todo.md` ([progress documents](todo.md)): one block per version with its concrete paths, release commit, RC number, and a status per step. Before step 1, show the release manager that instance and wait for an explicit go; then run it in order without asking again, stopping only when a step's check fails. The agent runs every command. The release manager only types the GPG passphrase and the ASF password, and performs actions that need their web login (see [permissions and credentials](#permissions-and-credentials)).

Before running, read the target branch's `tools/releasing/` scripts: their environment variables, invocation directory, and rewritten version files differ across maintenance branches, and older guide examples are not the script contract. Differences observed for 1.20.6, 2.2.2, and 2.3.1:

- JDK: the `release` profile enforces Java `[1.8.0,1.8.1)` on 1.x, so build with JDK 8; on 2.x it enforces `[11.*,)`, so build with exactly JDK 11 (2.3.0-rc2 received a -1 vote for JDK 17-built artifacts).
- `create_release_branch.sh` on 2.3 and later also rewrites the REST API version in `docs/static/generated/*.yml`.
- `create_binary_release.sh` on 1.x builds Python packages in a conda environment created by `dev/lint-python.sh` with `python setup.py sdist`; on 2.x in a uv environment with `uv build`, which also produces the universal `apache_flink_libraries-<v>-py2.py3-none-any.whl`. Both expect exactly 12 platform wheels from CI in `flink-python/dist`.

## Placeholders

`<v>` target version `x.y.z`; `<x.y>` its maintenance line; `<N>` RC number; `<wt>` the version's Flink worktree; `<rc>` the candidate's evidence directory `releases/<v>/rc<N>/`; `<jdk>` the branch's release JDK home; `<apache>` and `<fork>` the remote names for `apache/flink` and the release manager's fork `<fork-repo>`; `<fpr>` the signing key fingerprint; `<asf-id>` the release manager's Apache ID; `<profile-id>` the `org.apache.flink` Nexus staging profile ID. Maven steps run from `<wt>/tools` with `JAVA_HOME=<jdk> MVN=<wt>/mvnw`. Tee every script's output to `<rc>/logs/<step>.log`.

## Steps

| # | Step | Command or script (required environment) | Executor | Permissions and credentials | Directory and repository | Visibility and rollback | Output and check |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Preconditions | RM terminal: `export GPG_TTY=$(tty); echo test \| gpg --clearsign`. Agent: `echo test \| gpg --batch --pinentry-mode error --clearsign >/dev/null`; each RC row of [permissions and credentials](#permissions-and-credentials); `df -h <wt>` | RM types the passphrase; agent checks | GPG passphrase | any | Local | Agent check exits 0; the cache lasts 8 h, so repeat before a later batch of signing steps |
| 2 | Select the release commit | `git -C <wt> fetch <apache> release-<x.y>`; `git -C <wt> checkout --detach <apache>/release-<x.y>`; `gh run list -R apache/flink --workflow ci.yml --branch release-<x.y> --event push --limit 3 --json headSha,status,conclusion,url`; `git ls-remote <apache> 'release-<v>-rc*'` and the same for `<fork>`; `svn list https://dist.apache.org/repos/dist/dev/flink/` | Agent | Read only | `<wt>`, `<apache>` | Local | HEAD equals `<apache>/release-<x.y>`; its push CI run has the same `headSha` and `success`; clean `git status --porcelain`; no existing RC branch, tag, or dist/dev directory for `<v>-rc<N>` |
| 3 | Create the release branch | `cd <wt>/tools && JAVA_HOME=<jdk> MVN=<wt>/mvnw NEW_VERSION=<v> RELEASE_CANDIDATE=<N> releasing/create_release_branch.sh` | Agent | None | `<wt>/tools`; local branch `release-<v>-rc<N>` in the shared Git directory | Local; undo with `git checkout --detach <commit> && git branch -D release-<v>-rc<N>` | Commit `Commit for release <v>` on the release commit; `git show --stat HEAD` covers the POMs (the root POM also carries japicmp), `docs/config.toml`, `pyflink/version.py`, and on 2.3+ `docs/static/generated/*.yml`; `git grep -l -- '-SNAPSHOT' -- '*pom.xml' docs/static/generated` lists only files that also list it at the previous release tag (`flink-contrib` is outside the reactor) |
| 4 | Sign the tag locally | `git -C <wt> -c user.signingkey=<fpr> tag -s release-<v>-rc<N> -m "release-<v>-rc<N>"` | Agent | GPG cache | `<wt>` | Local until step 11; undo with `git tag -d` | `git tag -v release-<v>-rc<N>` shows `<fpr>`; the tag's commit equals step 3's commit |
| 5 | Start the Python wheel build | `git -C <wt> push <fork> refs/heads/release-<v>-rc<N>:release-<v>-rc<N>`; `gh workflow run nightly.yml -R <fork-repo> --ref release-<v>-rc<N>` ([5](#5-and-8-python-wheels)) | Agent | Push to the fork; fork Actions enabled | `<wt>`, `<fork>` | Public in the fork; delete the fork branch after the vote | Run ID recorded; its `headSha` equals the RC commit |
| 6 | Source release | `cd <wt>/tools && RELEASE_VERSION=<v> releasing/create_source_release.sh` | Agent | GPG cache | `<wt>/tools/releasing/release/` | Local; delete the directory to undo | `flink-<v>-src.tgz` with `.asc` and `.sha512`; `sha512sum -c`, `gpg --verify`; `verify-flink-release/scripts/check_source_archive.sh` passes |
| 7 | Stage Maven artifacts and close the staging repository | `cd <wt>/tools && JAVA_HOME=<jdk> MVN=<wt>/mvnw releasing/deploy_staging_jars.sh`; then close by REST ([7](#7-nexus-staging)) | Agent | Nexus user token in `~/.m2/settings.xml`; GPG cache | `<wt>`, `~/.m2` | Staging repository visible on repository.apache.org; undo by dropping it | Exactly one open repository from this deploy, containing `org/apache/flink/flink-core/<v>/`; after close, `type` is `closed` and no close rule failed; record its URL `https://repository.apache.org/content/repositories/orgapacheflink-<id>/` |
| 8 | Download the wheels | Wait for both `Build Python Wheels on ...` jobs, then download into `flink-python/dist` ([8](#5-and-8-python-wheels)) | Agent | Fork read | `<rc>/wheels`, `<wt>/flink-python/dist` | Local | 12 files matching `apache_flink-<v>-*.whl`; record run URL and artifact names |
| 9 | Binary release | `cd <wt>/tools && JAVA_HOME=<jdk> MVN=<wt>/mvnw RELEASE_VERSION=<v> releasing/create_binary_release.sh` | Agent | GPG cache | `<wt>/tools/releasing/release/` | Local | `flink-<v>-bin-scala_2.12.tgz` and `python/` with the sdists, 12 wheels (plus the libraries wheel on 2.x), each with `.asc` and `.sha512`; `sha512sum -c` and `gpg --verify` pass for every file |
| 10 | Upload to SVN dist/dev | `SVN_WC=$(mktemp -d)`; `svn checkout https://dist.apache.org/repos/dist/dev/flink --depth=immediates $SVN_WC/flink`; `mkdir $SVN_WC/flink/flink-<v>-rc<N>`; `mv <wt>/tools/releasing/release/* $SVN_WC/flink/flink-<v>-rc<N>/`; `svn add $SVN_WC/flink/flink-<v>-rc<N>`; then `svn commit -m "Add flink-<v>-rc<N>" --username <asf-id>` | Agent prepares; RM runs the commit and types the ASF password | ASF password, dist/dev write | `$SVN_WC` | Public; undo with `svn rm` of the directory | `svn list -R https://dist.apache.org/repos/dist/dev/flink/flink-<v>-rc<N>/` matches the local inventory; remove `$SVN_WC` |
| 11 | Push the RC tag | `git -C <wt> push <apache> refs/tags/release-<v>-rc<N>` | Agent | Committer push to `apache/flink` | `<wt>`, `<apache>` | Public; delete only when the RC is cancelled ([vote](vote.md)) | `git ls-remote <apache> 'refs/tags/release-<v>-rc<N>*'` peels to the RC commit |
| 12 | Website PR | Update `docs/data/flink.yml`, `docs/data/release_archive.yml`, and the announcement post per [preparation](preparation.md); push to the flink-web fork; `gh pr create -R apache/flink-web` | Agent | Push to the flink-web fork | Version's flink-web worktree | Public PR; do not merge before finalization | PR URL recorded; links name `<v>` and the Jira release-notes version ID |
| 13 | Verify the RC | Invoke `verify-flink-release` in pre-vote mode with version, RC, tag commit, dist/dev URL, staging URL, wheel run URL, and website PR | Agent | Read only | Verifier's own temporary directory | Read only | `PASS` for this exact RC before `[VOTE]`; on `FAIL`, cancel and rebuild with `<N>+1` |
| 14 | Clean build outputs | After step 13 passes: `git -C <wt> clean -ndX` to review, then `-fdX`; remove `<rc>/wheels` and the `~/.m2/repository/org/apache/flink/*/<v>` directories installed by step 7 | Agent | None | `<wt>`, `~/.m2` | Local, irreversible; keep `<rc>/logs` | `df -h` recorded; `<wt>` clean |

Record each step's result and evidence link in the round's `3-rc-build-todo.md` as it completes, and the RC identity (tag, commit, fingerprint, staging repository, dist/dev URL, wheel run, website PR) in `state.md`.

## Step commands

### 5 and 8: Python wheels

The branch's `nightly.yml` holds the wheel jobs; dispatching it in the fork also runs that workflow's test jobs, which do not gate the RC.

```bash
timeout 30 gh run list -R <fork-repo> --workflow nightly.yml --branch release-<v>-rc<N> --limit 1 --json databaseId,headSha,status
timeout 30 gh run view <run-id> -R <fork-repo> --json jobs \
  --jq '.jobs[] | select(.name | startswith("Build Python Wheels")) | [.name, .status, .conclusion] | @tsv'
timeout 600 gh run download <run-id> -R <fork-repo> -p 'wheel_*' -D <rc>/wheels
mkdir -p <wt>/flink-python/dist
find <rc>/wheels -name 'apache_flink-<v>-*.whl' -exec cp {} <wt>/flink-python/dist/ \;
ls <wt>/flink-python/dist/*.whl | wc -l   # must be 12
```

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

## Directories and repositories

| Item | Location | Purpose |
| --- | --- | --- |
| Version worktree | `releases/<v>/flink` | Detached at the release commit, then on `release-<v>-rc<N>`; every script runs from its `tools/` |
| Shared Git directory | The source repository's `.git` | Shared objects and refs for all version worktrees; RC branch and tag names are unique per version |
| `<apache>` remote | `apache/flink` | Fetch the maintenance branch; push only the RC tag (committer SSH) |
| `<fork>` remote | The release manager's `flink` fork | Push the RC branch and run the wheel workflow |
| flink-web worktree | `releases/<v>/flink-web` from a flink-web clone with the Apache and fork remotes | Website PR |
| RC evidence | `releases/<v>/rc<N>/` | Logs, downloaded wheels, inventory |
| Build output | `<wt>/tools/releasing/release/` | Source, binary, and `python/` artifacts before upload |
| SVN dist/dev working copy | `$(mktemp -d)` | One RC upload; removed after the commit |
| Maven local repository | `~/.m2/repository` | Shared by all worktrees; step 7 installs the version's artifacts here |
| Maven settings | `~/.m2/settings.xml` (mode 600) | Nexus token for servers `apache.releases.https` and `apache.snapshots.https` |
| GnuPG home | `~/.gnupg` | Signing key and `gpg-agent.conf` |

Record the concrete paths and remote names in the workspace's `workspace.md`, not in this skill.

## Permissions and credentials

| Item | Needed by | How to obtain | How to verify |
| --- | --- | --- | --- |
| Signing key in `KEYS` and id.apache.org | Steps 1, 4, 6, 7, 9 | See [signing key](#signing-key) | `curl -s https://dist.apache.org/repos/dist/release/flink/KEYS \| gpg --show-keys --with-colons \| grep -c <fpr>` is nonzero; `https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x<fpr>` and `https://keys.openpgp.org/vks/v1/by-fingerprint/<fpr>` return 200 |
| GPG passphrase cache | Same | `gpg-agent.conf` with `default-cache-ttl 28800`, `max-cache-ttl 28800`, `pinentry-program /usr/bin/pinentry-curses`, then `gpgconf --reload gpg-agent`; the RM caches the passphrase in step 1 | Step 1's non-interactive check |
| Nexus user token | Step 7 | RM logs in to repository.apache.org → Profile → User Token → Access User Token; the agent writes it into both servers of `~/.m2/settings.xml` | `GET $NX/staging/profiles` returns 200 and lists `org.apache.flink`; a wrong password returns 401 |
| SVN dist write | Step 10 | ASF account; dist/dev is writable by committers, dist/release by the PMC | The RM's earlier commit in `svn log -l 5 https://dist.apache.org/repos/dist/release/flink/KEYS`, otherwise the first commit |
| Push to `apache/flink` | Step 11 | ASF committer with linked GitHub account and SSH key | `gh api repos/apache/flink --jq .permissions.push` is `true` |
| Fork with Actions | Steps 5, 8 | RM's fork; enable Actions in the fork's web UI if disabled | `gh api repos/<fork-repo>/actions/permissions --jq .enabled` is `true` and `gh api repos/<fork-repo>/actions/workflows/nightly.yml --jq .state` is `active` |
| flink-web fork | Step 12 | RM's `flink-web` fork | `gh api repos/<web-fork-repo> --jq .permissions.push` is `true` |
| PyPI maintainer and API token | Finalization only | An existing owner adds the RM's own PyPI account as Maintainer of `apache-flink` and `apache-flink-libraries`; the RM creates an API token. Request early | The RM sees both projects under "Your projects" |
| PyPI quota | Before step 9 | Request an increase in a public pypi/support issue if needed; approval can take days | Used size: `curl -s https://pypi.org/pypi/<project>/json \| jq '[.releases[][].size] \| add'`; limit: the latest public pypi/support quota issue for that project; remaining space must exceed this round's `python/` size per project. No shared-account login is needed |
| Jira release permission | Finalization only | Flink PMC membership | `GET https://issues.apache.org/jira/rest/api/2/mypermissions?projectKey=FLINK&permissions=ADMINISTER_PROJECTS` with the RM's token shows `havePermission: true`; anonymous read access proves nothing |

### Signing key

Use an RSA 4096 key with sign and certify capability ([SC]) under the RM's Apache address. If the old key's private part is lost, do not renew it: generate a new key on the build host, append it to `KEYS` and keep every old key there (`svn co https://dist.apache.org/repos/dist/release/flink`, `(gpg --list-sigs <fpr> && gpg --armor --export <fpr>) >> KEYS`, `svn ci`), and upload it to `keyserver.ubuntu.com` (`gpg --keyserver hkps://keyserver.ubuntu.com --send-keys <fpr>`) and to keys.openpgp.org through its VKS API (`POST https://keys.openpgp.org/vks/v1/upload` with the armored key, then `POST https://keys.openpgp.org/vks/v1/request-verify` with the returned token and the address). The RM then clicks the keys.openpgp.org verification mail and adds the fingerprint at id.apache.org. `people.apache.org/keys` is regenerated daily from LDAP; waiting for it does not block the RC. An off-host backup of the private key is the RM's choice. Set the key as `user.signingkey` in each version worktree.

## ATR integration (to be completed)

Placeholder: which of the steps above ATR replaces or adds (for example RC upload and checks instead of step 10, vote and result handling, KEYS), with commands, permissions, and checks, will be filled in from the ATR research. Until then, run the steps above unchanged.

## Several versions in one round

Build versions one at a time, finishing a version through step 14 before starting the next. Running them concurrently on one host is unsafe:

- **Nexus staging**: implicit staging groups deploys by user, IP address, and user agent, and Maven 3.8.6 sends `Apache-Maven/<version> (Java <java.version>; <os>)`, so two versions deployed with the same JDK land in one open repository. Close each version's repository before the next deploy.
- **Maven local repository**: the worktrees share `~/.m2/repository`, and the branches' Maven 3.8.6 wrapper bundles maven-resolver 1.6.3 without the named file locks that let concurrent processes share it.
- **Disk**: one version's release output is about 1.3 GB (2.2.1 in dist/release), plus an equal SVN pristine copy, `target/` directories, and installed Maven artifacts; step 14 frees them before the next version.

## Quality while building

- Bind one `<v>-rc<N>` to its signed tag, commit, signing fingerprint and `KEYS`, source and binary files, ASC/SHA512, Nexus staging repository, Python files under `python/`, website PR, and corresponding CI runs. Confirm each wheel traces to this RC commit and check the branch-specific platform matrix separately from any `apache-flink-libraries` universal wheel. Use a different wheel build path only if its full matrix and provenance have been verified. Record each item's origin, hash, and upload result. Check Docker publishing readiness and access now; Docker images are finalized after the official release is available, not a required RC artifact.
- Before a replacement RC, preserve the prior RC's evidence, clear its build outputs, and return the clean worktree to detached HEAD at the newly selected maintenance-branch commit; never derive a new RC from the old RC commit by accident.
- Apply the installed `verify-flink-release` skill's quality checks while producing each package, CI artifact, and website PR: packaging, signing, license and notice coverage, provenance, build and runtime behavior, and version consistency. Investigate failures at their cause; do not continue with an apparently complete RC.
