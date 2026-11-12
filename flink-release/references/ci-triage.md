# CI failure triage

Use this when a branch CI job fails during Discovery, Preparation, or the CI-baseline gate. Classify every non-green job and record it in `2-ci-gate-todo.md` before ticking the CI-baseline items in `TODO.md`; the gate compares against the release commit's build, not against a sustained all-green window.

## Three kinds of CI

- **PR Azure build** — runs on each PR; reported only by the `flinkbot` "CI report" comment, not by GitHub checks or statuses.
- **Push `Flink CI`** — GitHub Actions `.github/workflows/ci.yml`, run on every push to the branch with the branch's default JDK.
- **Nightly** — `.github/workflows/nightly.yml`, an extended run. The daily schedule comes from `nightly-trigger.yml` on master and dispatches only the branches in its matrix. The community removes older maintenance branches from that list to save GitHub Actions resources. Check the schedule and the branch's recent runs:

```bash
timeout 30 gh api repos/apache/flink/contents/.github/workflows/nightly-trigger.yml --jq .content | base64 -d | grep -E '^ +- (master|release-)'
timeout 30 gh run list -R apache/flink --workflow nightly.yml --branch release-<x.y> --limit 5 --json databaseId,headSha,conclusion,createdAt
```

For an unscheduled branch the latest Nightly may be old; a committer can dispatch one with `timeout 30 gh workflow run nightly.yml -R apache/flink --ref release-<x.y>`, an external write that needs approval.

Nightly covers more than push CI. Compare the branch's two workflows in its worktree: Nightly typically adds the branch's non-default supported JDKs, a Hadoop 3 profile, the AdaptiveScheduler profile, and Python wheel builds on Linux and macOS.

```bash
timeout 10 grep -nE 'name: "|jdk_version|PROFILE=' .github/workflows/ci.yml .github/workflows/nightly.yml
```

## Pull the evidence

For GitHub Actions:

- List failed jobs: `timeout 30 gh run view <run-id> -R apache/flink --json jobs --jq '.jobs[] | select(.conclusion == "failure") | [.databaseId, .name] | @tsv'`.
- Read one job's log at a time: `timeout 30 gh api repos/apache/flink/actions/jobs/<job-id>/logs`. `gh run view --log-failed` can return nothing for these runs, so do not read an empty result as a clean log.
- In the log, find the failing step, the reported `TestClass.testMethod`, the exception/stack trace, and the process exit status. When no test case is named, record the failed process or step and its exit code.

For the PR Azure build: take the `buildId` from the `flinkbot` CI report link and read the build's result and commit, then its failed records with their log URLs, anonymously:

```bash
AZ=https://dev.azure.com/apache-flink/98463496-1af2-4620-8eab-a2ecc1a2e6fe/_apis/build/builds
timeout 30 curl -sS --max-time 30 "$AZ/<id>?api-version=7.1" | jq -r '[.status, .result, .sourceVersion] | @tsv'
timeout 30 curl -sS --max-time 30 "$AZ/<id>/timeline?api-version=7.1" | jq -r '.records[] | select(.result == "failed") | [.type, .name, .log.url] | @tsv'
```

Do not classify from a red icon or a Maven module name alone; read the log.

## Classify

- **Flaky** — the same job or test passes on an immediate re-run of the same commit, or the failure is an intermittent timing/race error (e.g. executor terminated, timeout) unrelated to the diff under test. Evidence: two runs of the same commit, one failing and one green, with the flaky job/test named.
- **Real regression** — the failure reproduces on re-run and traces to a specific commit or PR on the target branch; the error is deterministic and matches changed code. Evidence: the introducing commit/PR and the reproduced failing log.
- **Environment issue** — the failure is infrastructure rather than a test assertion: worker lost, Maven/CI process OOM-killed, disk/network/registry errors, or a job-level failure hitting unrelated modules. Evidence: the infra error line and the affected jobs.

## Act

- **Flaky** — re-run once or twice; if green, record the run IDs and mark non-blocking. If it keeps failing, reclassify as a real regression.
- **Real regression** — stop; locate the introducing commit/PR, then fix or revert on the branch, or move the issue out of scope. Do not freeze scope or cut an RC until resolved.
- **Environment issue** — re-run; if it persists, open or reference an Infra issue and record it. It blocks the CI-baseline gate only while it prevents a green run on the frozen commit.
