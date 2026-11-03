# CI failure triage

Use this when a branch CI job fails during Discovery, Preparation, or the CI-baseline gate. Classify every non-green job before ticking the CI-baseline items in `TODO.md`; the gate compares against the release commit's build, not against a sustained all-green window.

## Pull the evidence

For GitHub Actions:

- List jobs: `gh run view <run-id>` or `gh api repos/apache/flink/actions/runs/<run-id>/jobs --paginate`.
- Read logs: `gh run view <run-id> --log`, or per job `gh api repos/apache/flink/actions/jobs/<job-id>/logs`.
- In the log, find the failing step, the reported `TestClass.testMethod`, the exception/stack trace, and the process exit status. When no test case is named, record the failed process or step and its exit code.

For the PR-side Azure build (not reported to GitHub checks/statuses): read the `flinkbot` "CI report" comment on the PR to get the Azure build id, then read it anonymously at `https://dev.azure.com/apache/flink/_apis/build/builds/<id>`. Do not classify from a red icon or a Maven module name alone; read the log.

## Classify

- **Flaky** — the same job or test passes on an immediate re-run of the same commit, or the failure is an intermittent timing/race error (e.g. executor terminated, timeout) unrelated to the diff under test. Evidence: two runs of the same commit, one failing and one green, with the flaky job/test named.
- **Real regression** — the failure reproduces on re-run and traces to a specific commit or PR on the target branch; the error is deterministic and matches changed code. Evidence: the introducing commit/PR and the reproduced failing log.
- **Environment issue** — the failure is infrastructure rather than a test assertion: worker lost, Maven/CI process OOM-killed, disk/network/registry errors, or a job-level failure hitting unrelated modules. Evidence: the infra error line and the affected jobs.

## Act

- **Flaky** — re-run once or twice; if green, record the run IDs and mark non-blocking. If it keeps failing, reclassify as a real regression.
- **Real regression** — stop; locate the introducing commit/PR, then fix or revert on the branch, or move the issue out of scope. Do not freeze scope or cut an RC until resolved.
- **Environment issue** — re-run; if it persists, open or reference an Infra issue and record it. It blocks the CI-baseline gate only while it prevents a green run on the frozen commit.
