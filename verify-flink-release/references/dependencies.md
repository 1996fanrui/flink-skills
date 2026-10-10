# Internal verification dependencies

Check these when verification reaches the corresponding operation. The agent should install or configure missing tools it can safely provide and recheck them. Ask the requester only for inaccessible evidence, permissions, identity, or decisions the agent cannot provide. Do not turn a skipped or inaccessible check into `PASS`, and do not expose private key or token values.

| Operation | Required tools or access | Check before use |
| --- | --- | --- |
| Identify the RC and inventory | GitHub tag and CI links (`git`, `gh` or GitHub API), complete recursive `dist/dev` listing (`svn` or equivalent); dev@ archive once a vote exists | Confirm the exact version, RC, tag commit, URL set, and ability to enumerate nested directories; check the vote thread only in post-vote verification |
| Download and authenticate every package | `curl` or equivalent downloader, ASF `KEYS`, `gpg`, GNU `sha512sum`, `find`, `sort`, `diff`, `head`, `tail`, `mktemp` | Check the downloaded manifest and run the bundled artifact script from this skill directory; validate fingerprint and signer separately |
| Inspect and build packages | `tar`, `uv` for the bundled source archive script, target branch JDK and `./mvnw`; Python/uv for wheel installation | Read target branch build profiles and Python/platform matrix; install tools when feasible; run source, binary, and package checks |
| Cross-check staging and site | Nexus staging read access, Jira release notes, website PR and CI read access | Confirm each URL belongs to this RC and inspect current comments and failures |

A verifier who intends to cast a binding PMC +1 must personally download all signed source packages, validate their signatures, compile and test the provided source on their own hardware. The agent's report cannot substitute for that personal action.
