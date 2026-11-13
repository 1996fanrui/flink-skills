# Release scope triage

Use this in Discovery to find what the `[DISCUSS]` email must mention and in Preparation to decide what the RC waits for. Triage all target versions released together at once and record the result in the [stage documents](todo.md#stage-documents). Rescan before freezing; each rescan covers what changed since the scan time recorded in `1-pre-rc-todo.md`.

## Collect candidates

Scope is decided by Jira Fix Version, as the community works: the candidates are the unresolved issues whose Fix Version includes any target patch version. An issue with none of them is out of scope even if it affects a target version. A candidate is checked on every target branch released together, not only those its Fix Version lists: on each branch, determine whether the fix is already present and whether it is needed. Page through all results of each target version and merge them into one candidate list:

```bash
timeout 30 curl -sS --max-time 30 -G https://issues.apache.org/jira/rest/api/2/search \
  --data-urlencode 'jql=project = FLINK AND resolution = Unresolved AND fixVersion = "<x.y.z>"' \
  --data-urlencode 'fields=key,summary,status,priority,assignee' --data-urlencode 'maxResults=200' \
  | jq -r '.total, (.issues[] | [.key, .fields.status.name, (.fields.assignee.name // "-"), .fields.summary] | @tsv)'
```

## Check whether a branch has the fix

Check each candidate per target branch against its description, latest comments, linked PRs, and branch commits. Jira status spans all affected branches: an issue reopened only for another branch's backport is fixed on this one, and a landed commit does not settle an issue whose later comments report the problem still reproduces. A commit title may omit the Jira key, so `git log --grep` on the key is not proof of absence. Cross-check the PR's state, base branch, and merge commit, then confirm the commit carrying the change is on the branch; for a PR closed without a GitHub merge, find that commit from the PR's change and Jira comments.

```bash
timeout 30 gh pr view <pr> -R apache/flink --json state,baseRefName,mergedAt,mergeCommit
timeout 30 git merge-base --is-ancestor <commit> <apache-remote>/release-<x.y> && echo present
```

When the fix is merged elsewhere and only a backport is missing, hand it to the `flink-backport` skill or open the backport PR yourself before asking anyone.

A fix already on a target branch whose Jira issue lists the next patch version instead of the unreleased version being built is mislabeled: set its Fix Version to the version being released without asking the release manager.

## Classify

Classify each candidate by its impact on users and the progress of its fix:

- **Wait**: the impact is severe and a fix already exists, merged on any branch or in a ready PR; only the backport's review, merge, or missing PR remains.
- **Uncertain**: the impact may be severe but the fix is not ready: no PR, a stalled PR, an undecided approach, an unmet prerequisite, a backport only the original author can judge, or an unconfirmed problem.
- **Non-blocking**: test instability, CI, documentation, logging, Improvement, or a performance-only problem. Advance these as far as possible and welcome community volunteers; at the freeze, [settle](#settle-unresolved-issues) any still unresolved. An issue reopened because its test is still flaky belongs here.

Issues whose fix is complete and only need closing are tracked with the blocking items, unless someone else reopened or owns them; those are [never touched](#settle-unresolved-issues). The release manager confirms every final classification before the scope freeze. Once the release manager says the backports are done, scope is closed: do not propose further backports or include/exclude options.

## Contact owners

The deadline for all items is the planned RC cut date. Post one comment per Jira issue that names every target version still needing the fix, including versions missing from its Fix Version, so nobody has to ask again for another version. Mention its assignee; without one, the person actually working on it, such as the PR author; otherwise the original author; if nobody qualifies, drop the mention. Keep each comment under 25 words and polite.

- **Wait**: when the deadline passes unmet, the release manager decides whether to keep waiting or move it.
- **Uncertain**: without a reply by the deadline, move it; if the owner says they will fix it, wait.

Posting comments and moving or removing Fix Versions are external writes: show the drafted comments and changes and obtain approval first. Correcting a mislabeled Fix Version needs no approval.

```text
Wait:          [~<user>] Could you please get the backport for <versions> merged when you have time? We expect to cut the RC around <date>.
Uncertain:     [~<user>] Could you please confirm whether this will be fixed for <versions> when you have time? We expect to cut the RC around <date>.
Long-deferred: [~<user>] This has been moved across several releases without progress, so I'm removing the fix version. Please set it again once a fix is ready.
```

## Settle unresolved issues

At the freeze, and again once the RC commits are fixed, recheck every issue still unresolved with a target Fix Version and not yet in that version's [recorded decision](#record-the-decision), per branch that Fix Version names, as in [Check whether a branch has the fix](#check-whether-a-branch-has-the-fix) against the RC commit:

- **Not merged** (no fix commit on the RC commit and no merged PR to that branch): replace only that branch's patch version with the next patch version of the same line, using the Jira `update` operation (remove the old version, add the new one) and leaving other Fix Versions untouched. If the next version does not exist in Jira, stop and ask the release manager; do not create it.
- **Fix on the RC commit but the issue is unresolved** (reopened for a new failure, waiting on a follow-up for another branch, or simply not closed): keep the Fix Version. When someone else reopened or owns the issue, the release process never touches it: no Fix Version or status change, no closing, no comment, no request to split it.
- **Ambiguous** (a partial fix, or merged after the RC commit): keep the Fix Version.

Before moving, read the issue's Fix Version history. If it has already been moved across releases at least twice without substantive progress, remove the target Fix Version instead of moving it again, and post the long-deferred comment above so later release managers need not handle it again. Re-read the issue after each write.

```bash
timeout 30 curl -sS --max-time 30 'https://issues.apache.org/jira/rest/api/2/issue/FLINK-<id>?expand=changelog&fields=key' \
  | jq -r '.changelog.histories[] | .created as $c | .items[] | select(.field == "Fix Version") | [$c[0:10], (.fromString // "-"), (.toString // "-")] | @tsv'
```

### Record the decision

Report the issues kept in the last two cases to the release manager once, as one list with each branch's fix commit. Record their decision, quoted, with that list as a single entry in each target version's `state.md`, listing only the issues carrying that version's Fix Version; replace any earlier entry rather than adding another. Every later stage, including RC rebuilds, the vote, marking the Jira version Released (whose unresolved-issue warning these issues trigger), and finalization, reads that entry and does not ask again: the recorded issues do not block. Raise only an unresolved issue missing from the entry, then update the entry with the new decision.
