# Release notes

This page is the standard for a patch release's user-facing release notes in the flink-web announcement post. Past posts are not a reference. Curate after the scope freeze, and have the release manager confirm the result before [RC creation step 12](rc-creation.md#steps) opens the flink-web PR.

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

Page with `startAt` until every one of `.total` issues is read. `customfield_12310192` is the Release Note field. The full Jira release-notes link is `https://issues.apache.org/jira/secure/ReleaseNote.jspa?version=<version-id>&projectId=12315522`.

## Exclude

Leave out every issue that changes nothing a user runs or reads in the release:

- flaky tests and test instability;
- test-only changes, even when their Jira type is Bug;
- CI, build infrastructure, build stability, and test-scope or build-plugin dependency upgrades;
- release tooling and housekeeping, such as version bumps, japicmp baselines, and compatibility-test version lists;
- documentation-only and website-only changes;
- typos, code style, and refactoring without behavior change;
- issues introduced after the previous release on this line and fixed before this one, which no user saw.

Decide by what the change touches, not by its Jira type or title; read the linked PR's changed files when the title is ambiguous.

## Classify

Put every kept issue in exactly one of two sections, by what it means to a user, regardless of its Jira type:

- **Bug**: something worked incorrectly and now works: wrong results, failures, crashes, regressions, and security fixes, including CVE-driven dependency upgrades.
- **Improvement**: something already correct works better: performance, usability, error messages, and non-security dependency upgrades that change what users run.

Patch releases are mostly Bug. Omit the Improvement section when it has no items. An issue that fits neither section is not user-facing: exclude it.

## Write

- Each entry's title must read well to a user on its own. Reword a jargon Jira summary in the post; keep its `FLINK-<n>` key and link.
- Verify every claim beyond a title, such as a configuration option, API scope, or SQL example, against the target maintenance branch and its tests; a master commit or accepted FLIP alone is insufficient.
- Add a highlights paragraph when a kept issue is a security fix, a data-correctness fix, a regression fix, or has a nonempty Release Note field: name each such issue, and state each Release Note field's text.
- Sort entries by key within a section.

Skeleton of the post's introduction and `# Release Notes` section; `<count>` is the number of listed entries:

```markdown
The Apache Flink Community is pleased to announce the <ordinal> bug fix release of the Flink <x.y> series.

This release includes <count> bug fixes and improvements for Flink <x.y>. The list below excludes flaky and test-only, CI and build, documentation-only, and release-tooling changes. For a complete list of all changes see [JIRA](https://issues.apache.org/jira/secure/ReleaseNote.jspa?version=<version-id>&projectId=12315522).

<highlights paragraph, only when the Write rules require one>

We highly recommend all users upgrade to Flink <v>.

<# Release Artifacts section>

# Release Notes

## Bug

- [FLINK-<n>](https://issues.apache.org/jira/browse/FLINK-<n>) - <user-readable title>

## Improvement

- [FLINK-<n>](https://issues.apache.org/jira/browse/FLINK-<n>) - <user-readable title>
```

## Release manager review

Before opening the flink-web PR, show the release manager two lists: **kept** issues with key, Jira type, section, and displayed title (marking reworded ones), and **excluded** issues with key, Jira summary, and a one-line reason naming the exclusion rule. Open the PR only after the release manager confirms, and record the confirmation in `state.md`. If an issue gains or loses this Fix Version later, classify only that issue and confirm it the same way.
