# Per-version progress checklist (`TODO.md`)

Create `releases/<x.y.z>/TODO.md` as soon as Discovery resolves the target patch version, and keep it as that version's single stage-level progress record. It is a checklist, not a fact store: every tick names the evidence that justifies it, and every unchecked item names the blocking condition. Recompute checkboxes from evidence at the end of each stage; never tick by assumption.

## Template

Use these six stage sections in order, replacing `<x.y.z>` with the target version. Keep only items that apply to this patch release; add a specific blocker line only when evidence names it.

```markdown
# Apache Flink <x.y.z> release TODO

> Baseline <UTC date>; branch `<apache/release-x.y>` HEAD `<short-sha>`.
> Current stage: <stage>; blocked by: <summary or "none">.

## Stage 1 · Discovery / DISCUSS
- [ ] `[DISCUSS] Apache Flink <x.y.z> release` posted; evidence: dev@ thread URL.
- [ ] Release manager confirmed as a Flink committer; evidence: committer index or PMC roster link.
- [ ] Community consensus on scope reached; evidence: reply URLs or recorded consensus.

## Stage 2 · Scope freeze
- [ ] Every unresolved Jira issue with this Fix Version resolved or moved out; evidence: issue key + disposition link for each.
- [ ] Release notes and announced changes reconciled against the branch; evidence: Jira release-notes URL.
- [ ] Frozen scope recorded; evidence: branch HEAD SHA this freeze covers.

## Stage 3 · CI baseline
- [ ] Release commit's PR/Azure build `succeeded`; evidence: flinkbot CI report + Azure build URL.
- [ ] Latest Nightly before tagging green; evidence: run URL + commit SHA (only the last run needs to be green).
- [ ] Every non-green job triaged as flaky / real regression / environment; evidence: [CI triage](ci-triage.md) note per job.

## Stage 4 · RC build
- [ ] Release commit frozen and recorded; evidence: SHA.
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

## `state.md` vs `TODO.md`

`state.md` stores facts and their evidence: the current stage, exact version/RC/commit, evidence links, actions, results, blockers, and next action. Its old conclusions are overwritten as they change; reread it on resume.

`TODO.md` stores only stage-level progress: which stages are done, which items remain, and the evidence that ticked each. It is recomputed from `state.md` at each stage close and carries no standalone facts. When the two disagree, `state.md` evidence wins and `TODO.md` is recomputed from it.

## Stage gates

Check each gate before crossing the boundary; a failed gate is a hard stop.

1. **Scope freeze → RC build.** Proceed only when every issue with this version's Fix Version has an evidenced disposition and the frozen scope is recorded; otherwise stay in Stage 2.
2. **CI baseline → RC tag.** Create the tag only when the release commit's PR/Azure build is `succeeded` and the latest Nightly before tagging is green. Do not require a sustained all-green window; proceeding despite a red window is an exception the release manager must record, with its reason, in `state.md`/`TODO.md`.
3. **Verify → VOTE.** Send `[VOTE]` only after `verify-flink-release` passes for the exact candidate to be voted; otherwise stay in Stage 4/5 and rebuild a numbered new RC.
