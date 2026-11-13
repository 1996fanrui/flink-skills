# Release notes

This page is the standard for a patch release's user-facing release notes in the flink-web announcement post. Curate after the scope freeze, and have the release manager confirm the result before [RC creation step 11](rc-creation.md#steps) opens the flink-web PR.

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

The post has one intro and one list:

- **Intro**: one or two sentences giving how many issues the release fixes and at most 5 key fixes, chosen by user impact, such as security, data-correctness, and regression fixes and behavior changes. Name each key fix with a short user-facing phrase and its linked `FLINK-<n>` key. This is the only highlight; never write a bare list of keys.
- **List**: every kept issue appears exactly once under `## Bug` or `## Improvement`, sorted by key within a section. Each entry is the linked key and one user-readable sentence without a trailing period; reword a jargon Jira summary. The sentence states the new behavior for an issue with a nonempty Release Note field, and for a fix that takes effect only through a new option, where it names the option and its default instead of presenting the problem as fixed.
- **Links**: follow the convention of the 1.20.5 and 2.2.1 posts, the only use of past posts here: each entry's key links to `https://issues.apache.org/jira/browse/FLINK-<n>`, and the intro links the full Jira release-notes link from [Input](#input) as `[JIRA](...)`.
- Verify every claim beyond the Jira summary, such as a configuration option, API scope, or SQL example, against the target maintenance branch and its tests; a master commit or accepted FLIP alone is insufficient.

Skeleton of the post's introduction and `# Release Notes` section; `<count>` is the number of listed entries:

```markdown
The Apache Flink Community is pleased to announce the <ordinal> bug fix release of the Flink <x.y> series.

This release fixes <count> issues in Flink <x.y>, including <key fix phrase> ([FLINK-<n>](https://issues.apache.org/jira/browse/FLINK-<n>)) and <key fix phrase> ([FLINK-<n>](https://issues.apache.org/jira/browse/FLINK-<n>)). The list below excludes test-only, CI and build, documentation-only, and release-tooling changes; for a complete list of all changes see [JIRA](https://issues.apache.org/jira/secure/ReleaseNote.jspa?version=<version-id>&projectId=12315522).

We highly recommend all users upgrade to Flink <v>.

<# Release Artifacts section>

# Release Notes

## Bug

- [FLINK-<n>](https://issues.apache.org/jira/browse/FLINK-<n>) - <one user-readable sentence>

## Improvement   <!-- only when it has entries -->

- [FLINK-<n>](https://issues.apache.org/jira/browse/FLINK-<n>) - <one user-readable sentence>
```

## Release manager review

Before opening the flink-web PR, show the release manager the intro and two lists: **kept** issues with key, Jira type, section, and displayed sentence (marking reworded ones), and **excluded** issues with key, Jira summary, and a one-line reason naming the exclusion rule. Open the PR only after the release manager confirms, and record the confirmation in `state.md`. If an issue gains or loses this Fix Version later, classify only that issue and confirm it the same way.
