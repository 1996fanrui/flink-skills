# Flink release skills

This repository contains two [Agent Skills](https://developers.openai.com/codex/skills) for **Apache Flink main-project patch releases** (`x.y.z`, where `z > 0`):

- [`flink-release`](flink-release/SKILL.md) guides the full patch-release workflow, from evidence gathering before the first dev@ discussion through post-publication follow-up.
- [`verify-flink-release`](verify-flink-release/SKILL.md) independently checks a release candidate; the release skill also runs it before a vote.

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

## Installation

From the repository root, link the skills to this checkout. Existing ordinary directories are left untouched; move them before installing. Keep this checkout at the same path, or rerun installation after moving it.

```sh
install_skills() {
  skills_dir=$1
  test -f flink-release/SKILL.md && test -f verify-flink-release/SKILL.md || return 1
  mkdir -p "$skills_dir" || return 1
  for skill in flink-release verify-flink-release; do
    if [ -e "$skills_dir/$skill" ] && [ ! -L "$skills_dir/$skill" ]; then
      echo "Move the existing directory before installing: $skills_dir/$skill" >&2
      return 1
    fi
  done
  for skill in flink-release verify-flink-release; do
    ln -sfn "$(pwd -P)/$skill" "$skills_dir/$skill" || return 1
  done
}

install_skills ~/.claude/skills  # Claude Code
install_skills ~/.codex/skills   # Codex
```

## Use

Ask your agent: “Use `flink-release` to prepare the next patch release on the Flink 2.2 line.” To check an existing candidate, ask for `verify-flink-release` with the candidate's vote email or artifact links.

## Documentation

- [Project purpose and direction](PROJECT_PURPOSE_AND_DIRECTION.md) explains the motivation, current progress, future scope, and questions about community maintenance.
- [Skill design process](SKILL_DESIGN.md) describes how official procedures and past executions become reliable skills.
