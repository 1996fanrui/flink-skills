---
name: verify-flink-release
description: Independently verify an existing Apache Flink main-project patch release candidate, including identity, artifacts, provenance, licenses, builds, and candidate quality. Use for x.y.z-rcN with z greater than zero; do not create or publish a release.
---

# Verify a Flink patch release candidate

Verify one existing RC independently. Write any community-facing replies or drafts in English; communicate with the requester in their preferred language. Treat the RC and community release state as read-only. This skill covers only Apache Flink main-project patch releases. Do not send mail, cast a vote, or promote artifacts.

1. Read the bundled Markdown [Flink verification guide](references/official/verifying-flink-release.md) and [ASF release policy](references/official/asf-release-policy.md), then compare them with current upstream rules and the target branch. If current policy cannot be checked, mark its freshness `UNKNOWN`.
2. Identify the exact version, RC, tag commit, and candidate artifact links. Before a vote, use the release manager's RC inventory and original artifact sources; after a vote exists, also identify and check the original vote thread. Resolve ambiguous or multiple active candidates; never assume the highest RC number is valid.
3. Consult the internal [dependency checks](references/dependencies.md) as each verification operation becomes current. Resolve available tools and read access automatically; request only evidence or access the agent cannot obtain.
4. Run the [evidence and verification checks](references/checks.md) for this exact RC. Resolve paths relative to this skill directory. Do not reuse a previous candidate's artifacts, votes, or verification results.
5. Report `PASS`, `FAIL`, or `UNKNOWN` with evidence and impact. Never claim a check was performed if it was skipped. A draft for a community reply must state only work actually done in this run.

The release manager may use this preflight before a vote. A PMC voter must still perform the personal source checks required by ASF policy before casting a binding +1.

When verification exposes a reusable gap in this skill, trace the cause and directly improve its writable source instructions or checks, then verify the change. Show the evidence and diff to a human for judgment; after acceptance, contribute the improvement to the upstream skill repository through its review process. The RC remains read-only while improving the skill.
