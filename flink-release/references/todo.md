# Release progress documents

Each document answers one question, so no fact is kept twice:

- `releases/<x.y.z>/state.md` — what is true for this version: stage, exact version/RC/commit, evidence links, actions, results, blockers, and next action. Overwrite old conclusions as they change; reread it on resume.
- `releases/<x.y.z>/TODO.md` — how far this version has progressed: one checkbox per stage item, each tick naming its evidence. Recompute it from `state.md` and the stage documents at each stage close; it carries no standalone facts. When they disagree, the evidence wins.
- Stage documents at the workspace root — what remains to be done in the current stage, by whom, across all versions released together. Delete them when every version in that release round is complete; its durable facts live in each `state.md`.

## Stage documents

| Document | Stage | Content |
| --- | --- | --- |
| `1-pre-rc-todo.md` | Discovery through scope freeze | Blocking items only: Wait, Uncertain, and issues that only need closing, classified with [scope triage](scope.md) |
| `1-pre-rc-optional.md` | Discovery through scope freeze | Non-blocking items, open for community volunteers |
| `2-ci-gate-todo.md` | CI baseline, after the freeze and before tagging | Per branch, the release commit's push CI, the latest Nightly, and every non-green job, per [CI triage](ci-triage.md) |
| `3-rc-build-todo.md` | RC build | This round's instance of the [RC creation checklist](rc-creation.md): per version, the release commit, concrete paths, and each step's status and evidence, plus the credential checks |

Create a document when its stage becomes current. List only that stage's blockers; do not chase later-stage prerequisites such as a GPG key, a JDK, or credentials while scope is open, beyond a non-blocking notice for slow requests such as a PyPI quota increase. Start each document with its data time, the target versions and branches, and, for the scope documents, the deadline and last scan time.

In the scope documents, give each class one matrix: rows are Jira issues, columns are target versions, and each cell states what that branch needs, for example `Y — PR #n [k]`, `PR #n [k] awaiting review (<reviewer>, CI <state>)`, `needs a backport PR`, or `– (not affected)`. Add columns for the user impact (or, in the optional document, why it does not block) and whom to mention. The other documents list one row per item with its status, evidence, and the human action needed. Cite as `FLINK-<id> [n]` and `PR #<n> [n]`, and list every URL once under a closing `References` section.

## `TODO.md` template

Replace `<x.y.z>` with the target version. Keep only items that apply to this patch release.

```markdown
# Apache Flink <x.y.z> release TODO

> Baseline <UTC date>; branch `<apache/release-x.y>` HEAD `<short-sha>`.
> Current stage: <stage>; blocked by: <summary or "none">.

## Stage 1 · Discovery / DISCUSS
- [ ] `[DISCUSS] Apache Flink <x.y.z> release` posted; evidence: dev@ thread URL.
- [ ] Release manager confirmed as a Flink committer; evidence: committer index or PMC roster link.
- [ ] Community consensus on scope reached; evidence: reply URLs or recorded consensus.

## Stage 2 · Scope freeze
- [ ] Every unresolved Jira issue with this Fix Version resolved, moved to the next patch version, or its Fix Version removed; evidence: issue key + disposition link for each.
- [ ] Release notes and announced changes reconciled against the branch; evidence: Jira release-notes URL.
- [ ] Frozen scope recorded; evidence: branch HEAD SHA this freeze covers.

## Stage 3 · CI baseline
- [ ] Push CI on the release commit (the branch HEAD at build time) green; evidence: run URL + `headSha`.
- [ ] Latest branch Nightly recorded; evidence: run URL + commit SHA.
- [ ] Every non-green job triaged as flaky / real regression / environment; evidence: [CI triage](ci-triage.md) row per job in `2-ci-gate-todo.md`.

## Stage 4 · RC build
- [ ] `3-rc-build-todo.md` has no open row for this version.
- [ ] Tag `release-<x.y.z>-rc<N>` signed and pushed; evidence: tag URL + fingerprint.
- [ ] Source/binary artifacts, ASC/SHA512, Nexus staging, Python wheels built; evidence: staging URLs + hashes.
- [ ] Website PR proposed; evidence: PR URL.

## Stage 5 · VOTE
- [ ] `verify-flink-release` passed on this exact RC; evidence: result + RC identity.
- [ ] `[VOTE] Apache Flink <x.y.z> release` posted; evidence: thread URL + deadline.
- [ ] Vote passed (≥3 binding PMC +1, more positive than negative); evidence: tally + links.

## Stage 6 · Publish and close-out
- [ ] Approved artifacts published and read back; evidence: PyPI/Maven/SVN/dist URLs + tag.
- [ ] Announcements sent; evidence: mail archive URLs.
- [ ] Cleanup and follow-up done; evidence: items + links.
```

The six stages map onto the workflow as: Stage 1 = Discovery + Discussion, Stages 2–3 = Preparation, Stage 4 = RC creation, Stage 5 = RC verification + Vote and result, Stage 6 = Finalization + Follow-up.

## Stage gates

Check each gate before crossing the boundary; a failed gate is a hard stop.

1. **Scope freeze → RC build.** Proceed only when every unresolved issue with this version's Fix Version has an evidenced disposition (resolved, moved to the next patch version, or Fix Version removed, per [scope triage](scope.md)), `1-pre-rc-todo.md` has no open row for this version, and the frozen scope is recorded; otherwise stay in Stage 2.
2. **CI baseline → RC tag.** The release commit is the maintenance branch's latest HEAD at build time, so commits merged after a tentative freeze are included. Create the tag only when push CI on that commit is green and every non-green job of the latest Nightly is triaged. Do not re-run Nightly for commits merged after the freeze, and do not require a sustained all-green window.
3. **Verify → VOTE.** Send `[VOTE]` only after `verify-flink-release` passes for the exact candidate to be voted; otherwise stay in Stage 4/5 and rebuild a numbered new RC.
