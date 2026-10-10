---
name: flink-release
description: Orchestrate an Apache Flink main-project patch release from pre-discussion discovery through candidate verification, voting, publication, and follow-up. Resume across sessions. Use only for x.y.z releases with z greater than zero.
---

# Flink patch release

Act as the release manager's execution assistant. A requester needs to name only a maintenance line or target patch version. Write all community-facing mail, PR text, Jira release text, website text, and announcements in English. Communicate with the requester in their preferred language. Cover only Apache Flink main-project patch releases.

Read the bundled Markdown [Flink release guide](references/official/creating-flink-release.md), [ASF release policy](references/official/asf-release-policy.md), [publishing guide](references/official/asf-release-publishing.md), and [signing guide](references/official/asf-release-signing.md). Compare with current upstream policy and the target maintenance branch's release scripts. Resolve conflicts before acting. Before each stage, consult the internal [dependency checks](references/dependencies.md). Resolve what the agent can; ask for human input only when the current stage needs it. Label later-stage preparation as non-blocking.

## Workflow

1. [Workspace and resume](references/workspace.md): read the fixed workspace memory and existing release states; discover and reuse local Flink repositories, and create managed repositories only when needed.
2. [Discovery](references/discovery.md): derive the next patch version, collect branch, Jira, PR, CI, and mail evidence, give the requester checked review links and a complete `[DISCUSS]` draft before contacting the community.
3. Discussion: confirm the proposed release manager is a Flink committer. Send or update the `[DISCUSS]` email to dev@flink.apache.org using the discovery evidence, after checking for an existing thread. Record its URL, follow replies, and resolve objections. Advance on evidenced community consensus and an accepted release manager; discussion has no fixed voting window.
4. [Preparation](references/preparation.md): resolve release notes, backports, compatibility, permissions, packaging prerequisites, and release-related PR comments.
5. [RC creation](references/rc-creation.md): freeze a commit, build and stage one signed, traceable candidate; apply the verifier's quality criteria as artifacts are produced.
6. RC verification: invoke `verify-flink-release` on the exact RC in pre-vote mode and save its environment and results. On failure, stop that candidate, fix the problem, increment the RC number, rebuild, and reverify. Never mix links, votes, or checks from different candidates.
7. [Vote and result](references/vote.md): send `[VOTE]` only after preflight passes; handle findings and replacement candidates, count binding votes, and publish a separate `[RESULT]`.
8. [Finalization](references/finalization.md): publish only the approved candidate, then read back every public artifact, tag, version, and website link.
9. [Follow-up](references/follow-up.md): announce after public availability, clean up old artifacts, finish related tasks, and record improvements.

The fixed workspace is `~/flink-release-workspaces/`. Keep shared machine-specific memory in its `workspace.md` and one `releases/<x.y.z>/state.md` per version. Record the stage, exact version/RC/commit, evidence links, actions, results, blockers, and next action without secrets; recheck paths and remote state when resuming. Never share a writable worktree between versions or candidate artifacts and evidence between RCs. A later RC may reuse its version's worktree only after preserving the previous RC's evidence and clearing its build outputs.

Before external writes, check target state and authorization. Obtain specific approval for public or irreversible actions unless already authorized. Community consensus, independent PMC votes, and use of a person's signing identity remain human responsibilities. After each run, report the version, stage, completed actions with evidence links, blockers, and next action; mark completion only after public delivery and applicable follow-up are verified.

When a run exposes a reusable flaw in this skill, trace the cause and directly improve its writable source instructions or checks, then verify the change. Show the evidence and diff to a human for judgment; after acceptance, contribute the improvement to the upstream skill repository through its review process. Do not make every release run repeat the historical research used to design this skill.
