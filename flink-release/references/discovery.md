# Discovery before community discussion

- From the requested maintenance line or patch version, cross-check official Flink downloads, release tags, the `release-x.y` branch, Jira versions, and existing dev@ discussions or votes. Derive the next `x.y.z` with `z > 0`; do not increment a number from one source or start a duplicate discussion. Resolve conflicting version evidence before drafting.
- Fetch all accessible facts with `git`, `gh`, Jira, CI, and the public mail archive before asking the requester to look anything up. Record the previous official release on the same maintenance line and its date (including `x.y.0` before the first patch), comparison from its tag to the maintenance branch HEAD, merged fixes and backports, linked Jira issues and PRs, user impact, known blockers, CI status, and maintenance status. Cross-check a listed or blog date against the vote result and public announcement before calling it the actual publication date; past website dates have preceded vote completion. Include the year whenever writing a publication date in the discussion email. For hot-path dependency changes, obtain a focused benchmark and present any regression for community judgment; do not require every patch to run every benchmark. Mark inaccessible or uncertain facts explicitly.
- Reconcile every unresolved Jira issue assigned to the target Fix Version and every issue cited as a release highlight or pending decision against its description, latest comments, linked PRs, and commits in the target maintenance branch. Jira status covers all affected branches and is not, by itself, evidence that the target branch still lacks a fix. Treat a fix as delivered to this release only after checking the branch commit and its behavior; if the issue was reopened for another branch's backport, record it as fixed here rather than as a release blocker. Conversely, a landed commit does not settle an issue when later comments report the problem still reproduces. Separate delivered fixes, target-branch work still pending, and genuinely uncertain outcomes; investigate contradictory evidence before naming a blocker.
- Give the requester a concise evidence pack with exact, checked links: official downloads and previous tag, maintenance branch and comparison, relevant Jira version/issues or search, important target-branch PRs and CI runs, and any existing dev@ thread. Include what each link proves, the candidate release rationale, open questions, and a complete `[DISCUSS]` draft. The requester can open those links for review; ask them for a current-stage fact only if the agent cannot obtain it. GPG, Nexus, PyPI, and SVN publishing access are not discovery blockers.

## `[DISCUSS]` email shape

Use a plain-text dev@ mailing-list format after reconciling the issues. Write a complete email that can be copied and sent without filling placeholders. Get the sender's display name from the authenticated GitHub account with `gh api user --jq .name` and use it in the sign-off; if that field is empty, `null`, or inaccessible, obtain the name from the requester before producing the email. The GitHub identity does not by itself confirm willingness to serve as release manager. Write each Jira item on its own line as `- FLINK-<id> [n] - <one brief user-facing sentence>.` Put the Jira URL reference immediately after the key. Summarize the one problem users encounter or the one improvement they receive; use the Jira title and comments as evidence, not as text to copy or compress mechanically. Leave out reproduction conditions, internal components, causes, implementation, branch history, and release decisions unless a detail is essential to understand the user-visible effect. There is no fixed word limit: add only the words needed to make that effect clear. Put the reason for asking the community in the paragraph before pending items, rather than appending a separate question to each Jira summary.

List only fixes present in the target maintenance branch as completed, without PR references. For a pending item, cite its Jira issue and cite a PR only if its base is the target maintenance branch; do not cite a master-branch PR as a PR for this release. Include a pending section only for verified work or a failure requiring discussion, and include a CI item only for a verified relevant failure. Write each CI item as `- CI [n] - <exact displayed CI job name>: <observed failure>.` Link `[n]` directly to that job. When logs name failing test cases, give a real `TestClass.testMethod` example; if several cases failed, say how many. Add the exception only when needed to distinguish the failure. When no failing test case is reported, name the failed process and its exit status instead. A Maven module or "core tests failed" alone does not identify the CI job. Keep the item brief and do not infer an unconfirmed cause. If there is nothing to discuss, omit the entire pending section. An unresolved Jira status alone does not create a pending item. Collect all cited bare URLs in a consecutively numbered list at the end of the email; the number of items and references follows the evidence, not the example below. Describe each link by what it opens: a Jira JQL search is an issue list, not a Jira version page. Include the opening sentence offering to serve as release manager only when that person has confirmed their willingness; otherwise omit it.

```text
Subject: [DISCUSS] Apache Flink <version> release
To: dev@flink.apache.org

Hi everyone,

I would like to discuss a new Apache Flink <version> patch release. I can volunteer as the release manager.

Since <previous release and publication date including year> [1], the release-<line> branch has accumulated these notable fixes:

- FLINK-<id> [2] - <one brief sentence about the user-visible effect>.
- FLINK-<id> [3] - <one brief sentence about the user-visible effect>.

The branch comparison [4] and Jira issue list [5] show the changes and tracked issues.

Please let me know if there are any other issues we should consider before cutting a release candidate.

Best,
<display name from gh api user>

[1] <previous release announcement URL>
[2] <Jira issue URL for the first notable fix>
[3] <Jira issue URL for the second notable fix>
[4] <checked branch comparison URL>
[5] <checked Jira version page or issue list URL>
```

If there is verified pending work, insert this paragraph and only the applicable items before the closing invitation; append their references to the same numbered list:

```text
Before cutting a release candidate, please advise whether these items need action for this release:

- FLINK-<id> [next reference] - <one brief sentence about the user-visible effect>.
- CI [next reference] - <exact displayed CI job name>: <observed failure>.
```

These examples show the level of detail, not facts to reuse without checking the target job's logs:

```text
- CI [n] - AdaptiveScheduler / Test (module: core): the Java 8 test fork exited with code 239; no failing test case was reported.
- CI [n] - Default (Java 17) / Test (module: core): LocalRecoveryTest.testStateSizeIsConsideredForLocalRecoveryOnRestart errored.
- CI [n] - AdaptiveScheduler / Test (module: misc): two Kubernetes tests errored, including EnvSecretsDecoratorTest.testWhetherPodOrContainerIsDecorated.
```
