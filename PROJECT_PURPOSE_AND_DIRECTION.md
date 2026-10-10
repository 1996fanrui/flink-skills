# Project purpose and direction

## Why build community skills?

AI agents can gather evidence, run repeatable checks, prepare drafts, and resume work across a long release. These tasks consume release managers' time. Skills can reduce that repetitive work and make more frequent patch releases practical. Community consensus, release decisions, independent votes, and signing remain with people.

The value grows with use: when a release exposes a problem, the skill can be updated so the next release checks for it. This lets the community retain practical lessons that would otherwise stay in individual release managers' notes or old discussion threads.

## How do we make them reliable?

Start with the current official Flink and ASF release process. When designing a skill, investigate at least ten comparable past executions. For a release skill, that means tracing each release from its initial discussion through Jira issues, code and website PRs and their review comments, CI, release candidates, votes, verification, publication, and follow-up. The investigation must include problems and corrections, not just successful announcements.

The goal is to incorporate all problems identified in past and future releases into the skills. Their checks should run during both release preparation and independent verification, so the same problem is less likely to recur. Historical investigation belongs to skill design and improvement; a normal release run investigates its current version using the checks already built into the skill. The reusable design process is in [SKILL_DESIGN.md](SKILL_DESIGN.md).

## Current scope and validation

The current [flink-release](flink-release/SKILL.md) and [verify-flink-release](verify-flink-release/SKILL.md) skills target patch releases of the main Apache Flink project. The release skill is designed to cover the full workflow, from collecting evidence before the first dev@ discussion through candidate preparation, verification, voting, publication, and post-publication follow-up. It invokes the independent verifier for a specific release candidate. Research into ten recent Flink releases has helped refine the Discovery stage, which gathers evidence and drafts the initial community discussion. The release skill generated three discussion emails that were sent to dev@flink.apache.org:

| Patch version | Community discussion |
| --- | --- |
| 1.20.6 | [Discussion thread](https://lists.apache.org/thread/mjmb5hfgnxzy7081dk7oqbj4znv5fzoy) |
| 2.2.2 | [Discussion thread](https://lists.apache.org/thread/tzklqoy343q2nfm7kwzbgd8kpjgtq0t9) |
| 2.3.1 | [Discussion thread](https://lists.apache.org/thread/x68b0xvfxv78s7d1pq72r92y71b80k9r) |

Those three releases provide real-world validation of Discovery. They will be used to test and improve the later release stages. The full history of all ten releases has not yet been reconciled with every later-stage check, and independent RC verification has not yet been exercised end to end on these three releases.

## What could come next?

After the patch-release workflow is tested, future skills could cover major and minor Flink releases, connector releases, Flink CDC, and the Flink Kubernetes Operator. Similar connectors may reuse one release skill; other projects may need their own. Skills for diagnosing Flink problems could also help users troubleshoot their deployments.

## Two questions for the community

The skills are currently maintained in a [personal repository](https://github.com/1996fanrui/flink-skills). The first question is **whether the Flink community should maintain these skills**. If it agrees, contributions can follow the community's usual review process.

The second question is **where the skills should live**. A dedicated Flink community skills repository would let related workflows be reused across the many Flink code repositories, especially connectors. Alternatively, each skill could live beside the code it serves, such as the main Flink release skill in the Flink repository and a CDC release skill in the CDC repository. The choice of repository home is separate from the decision to maintain the skills as a community.
