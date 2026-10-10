# Designing reliable skills

Agent skills can take repetitive community work off maintainers' hands and make the process easier to repeat. Their reliability comes from combining the current official workflow with lessons from real executions. People still make community decisions, cast independent votes, and control their signing identities.

## Design method

1. **Start with the official workflow.** Read current project and ASF documentation, policies, and scripts. Trace the work from its first preparation step to its public result and cleanup. Keep the authoritative Markdown references needed when the skill runs, and check that they are still current.
2. **Study at least ten recent comparable executions while designing the skill.** For releases, include major, minor, and patch versions even when the skill handles only patches. Trace each one from discussion through every candidate and vote to publication, including available Jira comments, code and website PR reviews, CI, failures, and corrections. Keep source links and distinguish facts, inferences, and gaps. If fewer than ten examples exist, study all of them; a list of releases is not a completed investigation.
3. **Turn observed problems into checks.** Identify where each failure could have been caught. Apply the same standard while doing the work and while independently verifying it. Combine the checks reported by past verifiers, and check the full current set of artifacts and issues rather than only a list of historical examples.
4. **Make the workflow usable on its own.** Put the stages in `SKILL.md` and substantial details in references. Let the agent gather evidence, handle available tools, and save state for later sessions. Ask a person only for the current stage's unavailable access, identity, judgment, or authorization for public or irreversible actions. Package runtime instructions without personal paths or temporary research files.

## Validate and improve

Exercise the skill on real work and on cases it must reject, including missing evidence and a replaced release candidate. Treat it as a trial draft until the ten histories are traced, their checks are reconciled with the skill, and material gaps are closed; report untested stages plainly. Keep design research out of the distributed skill and Git change. When a new run exposes a reusable problem, fix the skill and its checks so the next run benefits; a normal run does not repeat the ten-release design study.
