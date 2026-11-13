# Verification report

Each verification run writes one standalone Markdown report for its RC, readable without the conversation or the logs. When the caller names a per-RC directory, such as the release workspace's directory for this candidate, write `<directory>/verification.md`; otherwise write `flink-<v>-rc<N>-verification.md` in the current directory. A rerun on the same RC replaces its report; a new RC gets its own report and never inherits results.

## Writing it

Each [check group](checks.md#one-parallel-pass) returns only its checkbox lines in the format below. Once every group, including the full source build, has finished, the coordinator assembles them under the group headings and writes the report in one pass. Results of the other groups may be relayed to the requester earlier, but the report waits for the build. Paste no raw logs: each line carries one line of evidence, such as the command and its exit code, key output, counts, or SHAs.

| Result | Line |
| --- | --- |
| `PASS` | `- [x] <what was checked> — <evidence>` |
| `FAIL` | `- [ ] **FAIL** <what was checked> — <evidence>; affected: <artifacts>` |
| `SKIPPED` | `- [ ] SKIPPED <what was checked> — <why it was not run>` |
| `UNKNOWN` | `- [ ] UNKNOWN <what was checked> — <why the result is indeterminate, or which evidence was inaccessible>` |

Never mark a check `PASS` that was not performed in this run.

## Overall result

An RC identity mismatch or failure of a required hash, signature, license, or source build makes the overall result `FAIL`. If necessary checks are `SKIPPED` or `UNKNOWN`, including a source build that has not finished, the overall result is `UNKNOWN`, never `PASS`. A pre-vote result may pass without vote-email checks; perform those checks once the email exists.

The summary lists every `FAIL` from all groups, including the build, each with its evidence, affected artifacts, and reproduction steps, so the release manager decides on a re-spin from the complete list and the next RC fixes every known problem. The next RC is verified from the beginning. The recommendation is, for the release manager, to start the vote or to cancel and re-spin; for a voter, the vote this run's evidence supports, which the voter casts personally ([voter independence](checks.md#voter-independence)).

## Template

Keep one line per check that the group's section in [checks](checks.md) requires, with one line per regression check and per build-matrix row; drop none.

```markdown
# Apache Flink <v>-rc<N> verification

- Version / RC: <v> / rc<N>; mode: pre-vote | vote (<vote thread URL>)
- Release commit: <sha>; tag: `release-<v>-rc<N>` (<tag URL>)
- Artifacts: ATR revision <rev> (<listing URL>) | dist <URL>
- Staging repository: <Nexus URL>
- Previous release for diffs: <old>
- Verifier, UTC time: <name>, <yyyy-mm-dd hh:mm>; environment: <OS>, JDK <...>, Maven <...>, Python <...>

## Summary

- Overall: PASS | FAIL | UNKNOWN
- FAILs: <none | one line each: check — evidence — affected artifacts — reproduction>
- Recommendation: <start the vote | cancel and re-spin as rc<N+1> | +1 | -1 | hold until ...>

## 1. Tag
- [x] Tag — `git verify-tag` good; peels to <sha>
- [x] Signer — fingerprint <fpr> in KEYS and the RC record; <algorithm, bits>

## 2. Source archive
- [x] Source archive — `check_source_archive.sh` exit 0; equals the tag's releasable source: <diff result>
- [x] Source LICENSE and NOTICE — <evidence>

## 3. Full source build
## 4. Maven staging
## 5. Wheels
## 6. Binary distribution
## 7. Python packages
## 8. PyFlink installation and small jobs
## 9. Local cluster smoke test

## 10. ATR revision
- [x] Inventory complete — listing `count` <n> equals the paths; <k> platform wheels, <libraries wheel>
- [x] Same files as checked — SHA512 of every file equals the copy groups 2 to 9 checked (pre-vote)
- [x] Checksums and signatures — `check_rc_artifacts.sh` exit 0, <n> files, all signed with <fpr>
- [x] ATR checks — 0 blocker; <c> concerns, <e> exceptions reviewed

## 11. Changes, release notes, CI, and website
```
