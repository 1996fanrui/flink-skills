# Release notes

Release notes are for Flink users. The issues Jira lists under the Fix Version are raw input; the published list is curated from them. The official guide's [Review Release Notes in JIRA](official/creating-flink-release.md#review-release-notes-in-jira) and [website pull request](official/creating-flink-release.md#propose-a-pull-request-for-website-updates) sections are the baseline; this page sets the curation rules. Curate after the scope freeze, and have the release manager confirm the result before [RC creation step 12](rc-creation.md#steps) opens the flink-web PR.

## Input

```bash
JIRA=https://issues.apache.org/jira/rest/api/2
timeout 30 curl -sS --max-time 30 "$JIRA/project/FLINK/versions" \
  | jq -r '.[] | select(.name == "<v>") | [.id, .released] | @tsv'        # exactly one row: <version-id>, false
timeout 30 curl -sS --max-time 30 -G "$JIRA/search" \
  --data-urlencode 'jql=project = FLINK AND fixVersion = <v> AND resolution = Fixed ORDER BY issuetype, key' \
  --data-urlencode 'fields=issuetype,summary,customfield_12310192' \
  --data-urlencode 'maxResults=100' --data-urlencode 'startAt=<offset>' \
  | jq -r '.total, (.issues[] | [.key, .fields.issuetype.name, .fields.summary, (.fields.customfield_12310192 // "")] | @tsv)'
```

Page with `startAt` until every one of `.total` issues is read. `customfield_12310192` is the Release Note field. The Jira release-notes link, which every announcement carries, is `https://issues.apache.org/jira/secure/ReleaseNote.jspa?version=<version-id>&projectId=12315522`.

## Exclude

Leave out every issue that changes nothing a user runs or reads in the release:

- test instability and flaky tests;
- test-only changes, even when their Jira type is Bug;
- CI, build infrastructure, and build stability;
- release tooling and release housekeeping, such as version bumps, japicmp baselines, and compatibility-test version lists;
- documentation-only and website-only changes;
- hotfix housekeeping, such as typos, code style, and refactoring without behavior change;
- issues introduced after the previous release on this line and fixed before this one, which no user saw.

Classify by what the change touches, not by its Jira type or title: read the linked PR's changed files when the title is ambiguous.

## Include

Keep user-visible bug fixes, improvements, security fixes, and dependency upgrades that change what users run, such as bundled or shaded libraries and CVE fixes; leave out test-scope and build-plugin upgrades. Each entry's title must read well to a user on its own. When a Jira summary is internal jargon, reword the displayed text in the post and keep its `FLINK-<n>` key and link. Verify every change described beyond its title, such as a feature, configuration option, API scope, completed FLIP subtask, or SQL example, against the target maintenance branch and its tests or parser; a merged master commit or accepted FLIP alone is insufficient. An issue with a nonempty Release Note field carries a compatibility or migration note: keep it and state the note in the highlights.

## Patch release post

Copy the structure of the previous patch release post on the same line:

- The introduction states that the list excludes test, build, CI, and documentation-only changes and links the Jira release notes for the complete list.
- An optional short highlights paragraph names notable fixes: security fixes, data-correctness fixes, regressions, and every Release Note field entry.
- The list starts from Jira's HTML release notes for the version: one `<h2>` section per Jira type (Bug, Improvement, Technical Debt, and so on) holding `[FLINK-<n>] - <title>` entries. Delete excluded entries and any section left empty; do not regroup by component.

## Release manager review

Before opening the flink-web PR, show the release manager two lists: **kept** issues with key, Jira type, and displayed title (marking reworded ones), and **excluded** issues with key, Jira summary, and a one-line reason naming the exclusion category. Open the PR only after the release manager confirms, and record the confirmation in `state.md`. If an issue gains or loses this Fix Version later, classify only that issue and confirm it the same way.
