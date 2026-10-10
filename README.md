# Flink release skills

Two [Agent Skills](https://developers.openai.com/codex/skills) support **patch releases of the Apache Flink main project** (`x.y.z`, with `z > 0`). They do not cover new major or minor versions, Flink CDC, connectors, or the Kubernetes Operator.

| Skill | Purpose |
| --- | --- |
| [`flink-release`](flink-release/SKILL.md) | Guides a release manager from evidence gathering before the first dev@ discussion through publication and follow-up, preserving stage and RC evidence across sessions. |
| [`verify-flink-release`](verify-flink-release/SKILL.md) | Independently checks one existing RC. The release skill invokes it before a vote; voters can invoke it separately. |

## Release stages

| Stage | What the agent prepares or checks | Decision or result |
| --- | --- | --- |
| Workspace | Read saved local paths and release states; find existing Flink repositories and prepare isolated worktrees as needed. | Resume without repeating previously answered setup questions. |
| Discovery | Determine the next patch version; fetch current branch, Jira, PR, CI, and mail evidence; give the requester checked review links and a `[DISCUSS]` draft. | An evidence-backed proposal before any community email. |
| Discussion | Send and follow the dev@ `[DISCUSS]` thread using the discovery evidence. | Community consensus and a release manager. |
| Preparation | After consensus, check Jira release notes, backports, compatibility, access, signing identity, build requirements, and release-related PRs. | A ready branch and resolved blockers. |
| RC creation | Build and stage a signed, version-consistent RC and check its source, binaries, Maven/Python packages, CI, and website PR as they are produced. | An RC with traceable artifacts, commit, and evidence. |
| RC verification | Run `verify-flink-release` against the exact RC before proposing it for a vote. Fix failures and fully verify a new RC. | A preflight result; voters still verify independently. |
| Vote and result | Draft `[VOTE]`, follow replies, handle cancellation or a replacement RC, and tally binding votes against the current PMC roster. | A recorded community vote and separate `[RESULT][VOTE]`. |
| Finalization | Publish only the approved RC; verify PyPI, Maven, ASF distribution, Git tag, Jira, Docker, and website. | Public artifacts and links work. |
| Follow-up | Announce the available release, clean up old artifacts, and finish related tasks. | Follow-up is recorded. |

The skills use internal, stage-specific dependency checks. The agent gathers accessible data and resolves missing tools it can handle; it asks for human help only when necessary for the current stage. Later-stage needs can be mentioned as non-blocking preparation. Human participation remains necessary for community decisions, independent PMC votes, signing identity, and authorization of public or irreversible actions.

## Installation

From the root of this repository, link the two skills to this checkout. Edits in this checkout are then available through the installed skills; keep the checkout at the same path or rerun the commands after moving it.

```sh
# Claude Code
test -f flink-release/SKILL.md && test -f verify-flink-release/SKILL.md &&
mkdir -p ~/.claude/skills &&
rm -rf ~/.claude/skills/flink-release ~/.claude/skills/verify-flink-release &&
ln -s "$(pwd -P)/flink-release" ~/.claude/skills/flink-release &&
ln -s "$(pwd -P)/verify-flink-release" ~/.claude/skills/verify-flink-release

# Codex
test -f flink-release/SKILL.md && test -f verify-flink-release/SKILL.md &&
mkdir -p ~/.codex/skills &&
rm -rf ~/.codex/skills/flink-release ~/.codex/skills/verify-flink-release &&
ln -s "$(pwd -P)/flink-release" ~/.codex/skills/flink-release &&
ln -s "$(pwd -P)/verify-flink-release" ~/.codex/skills/verify-flink-release
```

## Use

After installation, ask your agent in plain language or name a skill explicitly:

> Use `flink-release` to prepare the next patch release for the Flink 2.2 maintenance line. First collect the current evidence and review links, then draft the community discussion. Continue from the saved release state on later sessions.

> Use `verify-flink-release` to independently verify the active RC linked in this `[VOTE]` email. Report only the checks actually performed.

The verifier does not cast votes or publish artifacts. The release skill invokes it before drafting a vote.

## Maintenance

The [skill design process](SKILL_DESIGN.md) explains how past release failures become concrete checks when the skills are created or revised. A normal release run checks its **current** version and relevant community threads; it does not repeat the full historical investigation. The [requester's original statements](user-vision-verbatim.md) are preserved separately.

The stage overview and installation guidance draw on the presentation of [Gravitino's release README](https://github.com/apache/gravitino/blob/main/agent-skills/gravitino-release/README.md) and [release skill](https://github.com/apache/gravitino/blob/main/agent-skills/gravitino-release/SKILL.md). [Magpie's release-management skills](https://github.com/apache/magpie/blob/main/docs/release-management/README.md), the [Beam release guide](https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md), and the [Spark release process](https://spark.apache.org/release-process.html) informed the workflow review. The Flink skills follow Flink's own release policy and check prerequisites as needed during execution.
