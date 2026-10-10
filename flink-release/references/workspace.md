# Workspace initialization and resume

## Fixed entry point

Start every run at `~/flink-release-workspaces/`, independent of the current working directory or previous conversation. Read `workspace.md` if present and scan `releases/*/state.md` for in-progress versions before creating anything. Create the root and a short `workspace.md` on first use, with headings such as `Repositories`, `Local configuration locations`, and `Other notes`. The document is natural-language memory, not a fixed key/value schema. Keep one current statement per fact: update obsolete locations rather than appending contradictory notes.

The root has this layout. Create a directory only when its stage needs it:

```text
~/flink-release-workspaces/
  workspace.md
  repositories/                 # Only for projects missing a usable local repository
    flink/
    flink-web/
  releases/
    <x.y.z>/
      state.md
      flink/                     # Flink worktree for this version
      flink-web/                 # Website worktree, only when needed
      rcN/                       # Artifacts and evidence for this candidate
```

## Remember useful local facts

Record unusual or hard-to-rediscover locations in `workspace.md`: existing Flink and flink-web repositories, environment files, Maven settings, signing setup locations, or other setup facts learned from the requester. Ordinary locations that the agent can reliably rediscover need not be recorded. Record file paths and necessary context, never token values, passwords, private keys, or copied credential-file contents. Do not treat a saved path or old access result as current proof; check it when the corresponding stage needs it. Ask for a missing fact only after attempting discovery and only if it blocks the current stage. Update this document after a new answer or verified discovery so a later run need not ask again. If several releases run concurrently, serialize writes to this shared document and reread it before updating; keep each version's progress in its separate state file.

Once the target patch version is resolved, create or resume `releases/<x.y.z>/state.md`. Keep stage, worktree paths, source repository and remote identity, selected maintenance-branch commit, RC identity, evidence links, completed actions, blockers, and next action there. Record each RC's artifacts and evidence in its own `rcN/`; do not mix candidates. On resume, read the record, then recheck local paths, Git identity and commit, and external status before taking the next action. A missing or stale path triggers rediscovery, not an automatic repeat question or an assumption that an old action succeeded.

## Prefer existing repositories

Look first at saved nonstandard paths, the current checkout, and likely local code directories for `flink`; look for `flink-web` when a website task becomes current. Check repository identity from Git remotes and project contents, allowing a personal fork only when its Apache upstream can be identified. Do not select a repository by directory name alone, mutate its ordinary working tree, or ask the requester to locate a repository the agent can find. If several valid repositories remain ambiguous, ask the requester to choose once and remember that choice.

Use a verified existing repository as the Git source for new worktrees. Fetch missing or stale branch and tag data from the authoritative Apache remote; local data is not proof of current community state. If no usable local repository exists, create one ordinary managed Git clone under `repositories/` from the corresponding Apache remote, once per project. Use its updated remote-tracking maintenance branch when selecting a release SHA; do not base a new RC on a stale local branch. There is no need to clone five Git histories for five releases. The absence of `flink-web` does not block discovery or discussion.

Create each version's Flink worktree under its own release directory at a recorded maintenance-branch SHA with detached HEAD, so simultaneous versions do not contend for one checked-out branch. Create that version's website worktree only when website work becomes current, also on its own branch or detached base. Before reusing an existing worktree, confirm its Git source, version, branch, commit, and cleanliness. If the original local repository was moved or removed, preserve release state and any local changes, then repair or recreate the worktree from a newly verified repository; do not delete an uninspected directory.
