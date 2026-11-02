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

| Target `state` | Required |
| --- | --- |
| `pr_open` | `pr` with `pr_state` `open` |
| `merged` | `pr` with `pr_state` `merged` and `merged_at`, or a `note` naming the commit |
| `not_needed` | `note` with the reason |
| `needs_human` | `note` with the reason and the decision needed |

`pr` must contain all of these fields:

```json
{
  "pr_number": 12345,
  "author": "github-login",
  "pr_source": "platform",
  "pr_state": "open",
  "merged_at": null,
  "commits": []
}
```

`pr_source` is `platform` for a pull request this workflow opened and `external` for anyone else's. `commits` lists the SHAs on the target branch; keep it empty until the pull request merges.

The server checks every transition, and repeating the current state is allowed, so a retry is safe.

| Status | Meaning | What to do |
| --- | --- | --- |
| 401 | Bad token | Stop and tell the requester |
| 404 | Unknown Jira or version | Stop and report it |
| 409 | Illegal transition | Reread the cell. If someone else moved it, respect that state |
| 422 | Missing evidence | Fix the request |
