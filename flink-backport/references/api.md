# Backport tracker API

Use `scripts/tracker.sh` in this skill's directory. It sends the bearer token from `config.env` and exits non-zero on any HTTP error.

## Read

```sh
bash scripts/tracker.sh list <limit> <state> [<state>...]
```

Returns `{"jiras": [...]}`: Jiras with at least one cell in a given state, in priority order. `limit` is 1-100. Each Jira has `jira_key`, `jira_url`, `summary`, `jira_type`, `priority`, `jira_status`, `owner`, `origin_version`, `origin_pr_number`, `fix_merged_at`, and `cells`. Each cell has `version`, `branch`, `current_patch`, `is_master`, `state`, `note`, and `prs`.

## Write

```sh
bash scripts/tracker.sh update <FLINK-KEY> <minor-version> '<json>'
```

The body has `state`, and optionally `note` and `pr`. Omitting `note` keeps the stored note.

| Target `state` | Allowed from | Required |
| --- | --- | --- |
| `needs_backport` | `pending_check`, `needs_human` | Nothing |
| `pr_open` | `needs_backport` | `pr` with `pr_state` `open` |
| `merged` | `pending_check`, `needs_backport`, `pr_open` | `pr` with `pr_state` `merged`, or a `note` naming the commit |
| `not_needed` | `pending_check`, `needs_backport`, `needs_human` | `note` with the reason |
| `needs_human` | `pending_check`, `needs_backport`, `pr_open` | `note` with the reason and the decision needed |

The server rejects every other move between these states with 409. Repeating the current state is allowed, so a retry is safe. A `pending_check` cell becomes `needs_backport` before `pr_open`, and a `needs_human` cell becomes `needs_backport` before `merged`.

`pr` must contain all of these fields:

```json
{
  "pr_number": 12345,
  "author": "github-login",
  "pr_source": "platform",
  "pr_state": "open"
}
```

`pr_source` is `platform` for a pull request this workflow opened and `external` for anyone else's. The server reads a merged pull request's merge time and commits from GitHub; a `pr` that sends `merged_at` or `commits` is rejected with 422.

| Status | Meaning | What to do |
| --- | --- | --- |
| 401 | Bad token | Stop and tell the requester |
| 404 | Unknown Jira or version | Stop and report it |
| 409 | Illegal transition, or the reported pull request is not merged on GitHub or merged into another branch | Reread the cell and the pull request. If someone else moved the cell, respect that state |
| 422 | Missing evidence or unknown field | Fix the request |
| 502 | The update was stored, but recording the merge failed | Retry the same update; it completes the merge |
