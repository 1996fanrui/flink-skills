# Verification evidence and checks

## Evidence baseline

Build a single `version + rcN + commit` manifest from the release manager's RC inventory, Apache Trusted Releases (ATR) revision, signed Git tag, Nexus staging repository, website PR, and CI run. Cross-check every link, version, timestamp, and artifact against its original source. In pre-vote mode, do not require a `[VOTE]` email that does not yet exist. When a vote exists, additionally cross-check its original thread against the manifest. A reference to a different RC fails verification; never reuse votes or verification results from a previous RC. Record the verifier, UTC time, and OS/JDK/Maven/Python environment in the [report](report.md) header, and the original URLs, artifact SHA512 values, commands, and exit codes as its evidence lines. Write command logs to a task-specific temporary directory; on success, inspect only exit codes and necessary result fields, and on failure inspect relevant log excerpts. Use a unique system temporary directory and clean it up promptly. Keep reviewable evidence in a caller-designated location when needed.

## One parallel pass

Check the whole candidate in one pass so that every problem is found before anyone decides on a re-spin, and one re-spin fixes them all. The check groups below share nothing with each other, and each starts as soon as its own inputs exist, without waiting for the rest of the candidate. Run each as its own subagent or process with its own working directory and log, returning only its checkbox lines for the [report](report.md), and finish every group even when another group has already failed. Once its inputs exist, a group should finish in about 10 minutes, except the [full source build](#3-full-source-build), which is the long pole: of the groups sharing its trigger, start it first. Once every group has finished, the coordinator assembles the single report as [writing it](report.md#writing-it) describes. Run bundled `scripts/` commands from the parent `verify-flink-release/` skill directory. Verify the source, binary, Maven, and Python artifacts separately, each against its own LICENSE and NOTICE.

| Group | Inputs | Pre-vote trigger |
| --- | --- | --- |
| 1. Tag | Pushed RC tag, `KEYS` | Step 5: tag pushed |
| 2. Source archive | Source archive | Step 6: source release created |
| 3. Full source build | Source archive | Step 6: source release created; start first |
| 4. Maven staging | Closed staging repository | Step 7: staging repository closed |
| 5. Wheels | Platform wheels, their Nightly run | Step 8: wheels downloaded |
| 6. Binary distribution | Binary archive | Step 9: binary release created |
| 7. Python packages | `python/` | Step 9: binary release created |
| 8. PyFlink installation and small jobs | `python/` | Step 9: binary release created |
| 9. Local cluster smoke test | Binary archive | Step 9: binary release created |
| 10. ATR revision | ATR revision `<rev>` | Step 10: ATR upload done |
| 11. Changes, release notes, CI, and website | Tag, CI runs, website PR | Step 5: tag pushed; the website part at step 11: website PR opened |

The steps are those of the release manager's RC creation checklist: in pre-vote mode during the build, the release manager hands over each input as its step completes, so the groups run alongside the remaining build steps. In vote mode every input already exists, and each group starts as soon as its downloads finish.

`<old>` is the previous official release on the same maintenance line, tagged `release-<old>`. The diffs against it are the net for problems no listed check anticipates: each difference must trace to a commit or Jira issue in `release-<old>..release-<v>-rcN`, and an unexplained difference is `FAIL`. 1.20.6-rc2's empty Git commit ID showed up as a difference from 1.20.5, whose jars carry their real commit.

### Inputs

Copy or download each input into the verifier's own directory and check only that copy. In pre-vote mode during the build, take the tag from `apache/flink`; the source archive, binary archive, and `python/` files, each with its `.asc` and `.sha512`, from the release manager's build output directory; the wheels with their Nightly run URL and artifact names; and the staging repository URL. Group 10 then confirms that the ATR revision holds exactly these files.

From the ATR revision (all inputs in vote mode; group 10's in pre-vote mode), obtain the complete **recursive** remote file listing of this RC's ATR revision `<rev>` for version `<v>`, including `python/` and any other subdirectories, from `https://releases.apache.org/api/release/paths/flink/<v>/<rev>?limit=1000`; enumeration is complete when its `count` equals the number of returned paths. Download each file from `https://releases.apache.org/download/path/flink/<v>/<path>`, which serves the release's latest revision, so confirm before and after downloading that `https://releases.apache.org/api/release/get/flink/<v>` reports `latest_revision_number` `<rev>`. Outside the download directory, save a manifest containing one **RC-root-relative artifact path** per line (`python/<wheel-name>.whl`, for example), excluding `.asc`, `.sha512`, and `KEYS`; also retain the listing URL, retrieval time, and original listing. Cross-check the list with the release manager's RC inventory and the target branch's `tools/releasing/create_binary_release.sh` inventory, including the source and binary distributions and the exact Python wheel/platform count required for that branch (12 for branches whose script requires 12). Count platform wheels separately from any universal libraries wheel. Do not infer completeness from the top-level index alone. Download **every artifact in every subdirectory**, its adjacent `.sha512` and `.asc`, and the ASF `KEYS` file **outside the RC download directory**. Preserve the `flink-x.y.z-rcN` directory name and relative paths. Download the source archive first, so the source build can start.

Download `<old>`'s source and binary distributions and `python/` files from `https://dlcdn.apache.org/flink/flink-<old>/`, which keeps the RC's layout. `https://archive.apache.org/dist/flink/flink-<old>/` serves the same files at well under 1 MB/s, so use it only once dlcdn no longer has `<old>`. A published release never changes: download it once per version and reuse it for every RC.

### 1. Tag

Verify the tag's signature and that it peels to the manifest's commit. Independently compare the signing fingerprint with the release manager's RC record and `KEYS`; after the vote starts, cross-check its email as well. Check the key algorithm and strength against the current ASF signing policy.

### 2. Source archive

Run `scripts/check_source_archive.sh <source-tgz>` to check archive readability, safe extraction paths and entry types, LICENSE/NOTICE, AppleDouble files, and `__MACOSX`. Extract the source only after that check passes. Compare the source release with the releasable source at the **RC tag commit**; inspect for other unexpected binaries or temporary files, and audit its LICENSE and NOTICE. Run `scripts/diff_archive_entries.sh <old-source-tgz> <rc-source-tgz> <old> <v>`. Inspect source headers, POM versions including quickstarts, generated REST YAML versions, and README contents for incorrect versions or leftover `SNAPSHOT` markers.

### 3. Full source build

Derive the required JDK/Maven build and test matrix from the target branch's release guidance and CI, then compile the downloaded source archive as provided and execute every required row in a clean environment, including the applicable full build, license/style checks, and tests. Record each skipped row or check as `SKIPPED` with its reason. If a platform cannot be tested locally, mark it `SKIPPED` and collect direct evidence from an independent check; do not turn that gap into PASS.

### 4. Maven staging

Run `scripts/diff_staging_with_central.sh <staging-repository-id> <v> <old>`, which compares the staged artifactIds and each artifact's files with `<old>` on Maven Central. Confirm the staging repository is closed without a failed rule, and verify the staging POM, main JAR, sources, javadoc, signatures, versions, and each JAR's LICENSE and NOTICE. Check the staged class-file versions against the branch's compatibility matrix; the build JDK alone does not establish them. Maven artifacts for 2.3.0-rc2 received a -1 vote because they were built with JDK 17. `.flink-runtime.version.properties` in the staged `flink-runtime-<v>.jar` must name the RC tag commit, as in the [binary distribution](#6-binary-distribution).

### 5. Wheels

Run `scripts/check_python_license_files.sh <wheel-directory>`: every wheel must ship both LICENSE and NOTICE, as the current [ASF policy](https://www.apache.org/legal/release-policy.html#licensing-documentation) requires, and a missing one is FAIL; the older Flink verification guide's "Python artifacts only require an Apache License file" is wrong. Trace every wheel to an artifact of the `Build Python Wheels` jobs in the `nightly.yml` run dispatched on the RC tag, whose `headSha` is the **RC tag commit**, and compare wheel filenames, supported Python versions and platforms, and expected count with the target branch's release script. A matching filename or count alone does not establish provenance.

### 6. Binary distribution

Before extracting each binary convenience distribution, independently reject absolute or traversal paths, escaping links, and special files. Run `scripts/diff_archive_entries.sh <old-binary-tgz> <rc-binary-tgz> <old> <v>`, then `diff -r` the extracted `conf/`, `bin/`, `LICENSE`, `NOTICE`, and `licenses/` of both. Each added, removed, or re-versioned JAR must match a dependency change in the release's commits and in the NOTICE diff. Audit the exact bundled contents, including the dependency licenses and notices inside the JARs, against the distribution's LICENSE and NOTICE. RAT or a clean source distribution cannot stand in for binary NOTICE verification: 2.2.1-rc2 was cancelled over an omitted `log4j-layout-template-json` entry.

`.flink-runtime.version.properties` in `lib/flink-dist-<v>.jar` must name the RC tag commit, as the same file in `<old>` names its own; an unresolved `${git.commit.id}` is FAIL (1.20.6-rc2 was built in a linked Git worktree, which the build's git-commit-id plugin cannot read).

### 7. Python packages

Run `scripts/diff_archive_entries.sh` on each sdist and on each wheel paired with `<old>`'s wheel of the same platform tag; the 1.20.6 PyFlink sdist diff, for example, shows the NOTICE added by FLINK-41467. Run `scripts/check_python_license_files.sh <download-directory>/python`, which applies the [wheels](#5-wheels) LICENSE and NOTICE rule to the sdists as well. Audit each package's bundled dependency licenses and notices against them. Compare each package's declared dependencies with the source release and with `<old>`: a pemja dependency was present in the 2.1.2 source package but absent from a wheel.

### 8. PyFlink installation and small jobs

Independently install the local platform's wheel and the sdist, each into a clean environment with a Python version the branch supports; check the import and the key dependencies, and run a small Table API job and a small DataStream job.

### 9. Local cluster smoke test

Start a local cluster from the binary distribution. Run the WordCount example and a SQL Client query; inspect exit codes and logs. The JobManager log's `Rev:` must name the RC tag commit; `Rev:DeadD0d0` is FAIL. For each critical or motivating fix in the release discussion, add a focused regression check against the packaged RC at the affected boundary when feasible; record `UNKNOWN` with the reason when it cannot be reproduced.

### 10. ATR revision

In pre-vote mode, confirm that each file of the revision has the SHA512 of the copy that groups 2 to 9 checked; a file that differs is FAIL. Run `scripts/check_rc_artifacts.sh <download-directory> <KEYS-file> <x.y.z> <rcN> <remote-artifact-manifest>`. The script rejects invalid paths, extra or missing files at any depth, invalid checksums, non-ASCII-armored signatures, and invalid signatures. Confirm that every artifact is signed with the [tag's](#1-tag) verified fingerprint; the presence of a key in `KEYS` alone does not prove that the expected signer signed the artifacts. Missing files or invalid hashes/signatures are FAIL.

Once `https://releases.apache.org/api/checks/ongoing/flink/<v>/<rev>` reports `ongoing` 0, page through `https://releases.apache.org/api/checks/list/flink/<v>/<rev>?offset=<o>&limit=1000` until the collected rows equal its `count`. Any `blocker` is FAIL. Explain each `concern` and `exception`, for example by a RAT exclusion in Flink's root POM, which ATR does not read.

### 11. Changes, release notes, CI, and website

Review the changes from `<old>` to this tag for suspicious code, dependency, API, or state-restore changes, including modified or removed compatibility tests; resolve findings against the target branch and Jira evidence. Reconcile the official release notes against all Jira issues in this Fix Version with a nonempty Release Note field, including breaking SQL or migration changes. Check each claimed feature, configuration, API scope, and FLIP subtask against the target release branch rather than master or the accepted proposal alone.

Confirm each CI or Nightly job ran the relevant branch and commit recently enough to cover this RC; an old green mirror does not count. Examine every failed job and the evidence for its fix; do not waive a failure merely because it is called flaky or infrastructure-related.

Check the website PR's download links, Jira release-notes version ID, announcement date and patch ordinal, and other links. The post's intro highlights at most 5 fixes, each with its FLINK key, and links the full Jira release notes; the release notes have only Bug and Improvement sections, give every listed issue a one-sentence description with its key linked to its Jira issue page and no bare key lists, and list no flaky or test-only, CI or build, or documentation-only issues even if Jira's generated notes include them. Confirm that feature descriptions match the RC. Record unresolved PR review comments and merge conflicts. Before and during voting, an unmerged website PR or an inactive final download link is not by itself a failure; once a vote exists, its pending state must match the vote email.

## Voter independence

Before an independent PMC voter casts a **binding +1**, [ASF policy](https://www.apache.org/legal/release-policy.html#release-approval) requires that person to download **all signed source packages onto their own hardware**, verify each against ASF release requirements, validate every source signature, compile the source as provided, and test the result on their platform. The voter must perform and record those actions independently; the RM's report cannot substitute. An RM self-check covers all required and executable quality checks. The older [Flink verification guide](https://cwiki.apache.org/confluence/spaces/FLINK/pages/73631094/Verifying+a+Flink+Release) says voters need not perform every listed check; apply that statement only to additional Flink checks beyond this ASF minimum, with the RM ensuring collective coverage. A verification-reply draft must state only checks performed in this run and their results; do not determine a person's binding status or cast their vote.
