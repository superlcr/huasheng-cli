# Scripting and automation

[简体中文](automation.zh.md) · **English**

This page covers stable use from scripts, CI, and batch jobs. For interactive use, see the
[main README](../README.md).

## JSON output

Add `--json` to any command. Field names use `snake_case`. The contract below is stable: fields may be
added, but the shape of success and failure output does not change.

**Success** — standard output is the data itself (no envelope):

```console
$ hs project show --json
{"pid": 123456789012345, "state": "READY", ...}
```

**Failure** — the exit code is not `0` and standard error ends with exactly one JSON error object
(`hs make` may write single-line `{"event":...}` lines before it):

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "...",
    "retryable": true,
    "suggested_action": "retry",
    "next_command": "hs make --pid ... --mode mg",
    "retry_after_ms": 42000
  }
}
```

- `suggested_action` is one of `login` · `topup` · `retry` · `null`
- `next_command` appears only when there is a command you can actually run, pid filled in
- `retry_after_ms` (`RATE_LIMITED`, `DAILY_LIMIT`, `RUN_CONCURRENCY_LIMIT`, and a retryable
  `PLAN_CONTINUATION_UNCERTAIN`) says how long before trying again helps; `retry_at`
  (daily limit) is when the allowance resets, as ISO 8601 with `+08:00`
- Usage errors (unknown command, subcommand or option) are JSON too, with code `UNKNOWN_COMMAND`
  or `INVALID_INPUT` and exit code `2`
- `update: {latest, command}` is added to JSON objects (success and error) when a newer `hs` is known
  locally. It is only an extra field; array-shaped output never gets it

### Exit codes

Anything other than `0` is a failure, so `!= 0` checks keep working.

| Code | Meaning | What to do |
|---|---|---|
| `0` | success | |
| `1` | the command failed | read `error.code` |
| `2` | usage error, nothing was run | fix the command line |
| `4` | `hs make` only: the video or export failed, or anything not listed here | inspect; `resume` |
| `5` | `hs make` only: safety limit, `--deadline`, `--stall-timeout`, or the running-task limit stayed full | inspect, then `resume` |
| `6` | out of credits, membership needed, or today's limit used up (`INSUFFICIENT_POINTS`, `VIP_REQUIRED`, `DAILY_LIMIT`, `MEMBERSHIP_OR_LIMIT_REQUIRED`) | top up / wait for `retry_at` |
| `7` | result unknown: `WRITE_OUTCOME_UNKNOWN`, `CREATE_OUTCOME_UNKNOWN`, `*_UNCERTAIN` with `retryable: false` | **check state before retrying** |
| `8` | a person has to sign in: `NO_CREDENTIAL`, `CREDENTIAL_EXPIRED`, `NOT_LOGGED_IN`, `CSRF_FAILED` | `hs auth login` |
| `9` | `ACCOUNT_RESTRICTED` | contact support; retrying will not help |
| `75` | temporary: `RATE_LIMITED`, `NETWORK_ERROR`, `RUN_CONCURRENCY_LIMIT`, `STREAM_IDLE`, `DOWNLOAD_TIMEOUT`, `CLIP_BUSY`, `CALL_BUDGET_EXHAUSTED`, a retryable `HTTP_ERROR`, `NOT_LOGGED_IN` with `suggested_action: "retry"` (hs already renewed the session), `*_UNCERTAIN` with `retryable: true` (e.g. `PLAN_CONTINUATION_UNCERTAIN`) | run the same command later, after `retry_after_ms` when given |

`retryable: true` on any other code (for example `UPLOAD_FAILED`) means trying again may help, but
its exit code stays `1` (`4` in `hs make`).

### `hs make`

- The moment the project exists, **standard error** gets one line
  `{"event":"hs.created","version":1,"at":...,"pid":...,"resume":"hs make --pid ..."[,"recovered":true]}`
  — always, not only with `HS_PROGRESS=1`. If your tool kills the process, run `resume` — never the
  original command, which makes a second video. `recovered: true` means Huasheng did not confirm the
  creation and hs found the video again in your recent videos instead of creating another one.
- Standard output holds **only** the final result, one JSON document spread over several lines — parse
  all of it. When `hs make` gets far enough to report a step and the exit code is not `0`, the result also
  carries `error` (the same object written to standard error) and `resume`; a failed export keeps
  the old `export_error` string next to `error`.
- **When `hs make` stops before it can report a step** (credits, sign-in, an unknown creation, a
  temporary error: exit codes `6`, `7`, `8`, `9`, `75` and early `4`s), standard output is **empty** and
  `{error, pid, resume}` is only on standard error. Always read `error` from standard error.
- With `--json` and standard error not a terminal, human progress lines are left out: standard error
  holds the `hs.created` line (once the project exists) and the `{error, pid, resume}` object on
  failure, plus `hs.progress` lines when `HS_PROGRESS=1`. Every event line is one line starting with
  `{"event":`; the error object is the last thing written.

### Progress events

`HS_PROGRESS=1` writes versioned `{"event":"hs.progress","version":1,...}` lines to standard error:
`hs make` progress, and `kind: "rate_limit_wait"` whenever any command waits more than 5 seconds for
the account's allowance. Without `--json`, such waits (and waits for a free task slot) print one human
line instead; with `--json` they print nothing.

### Clip edits

Without a terminal or with `--json`, clip edits wait up to 30 seconds for the change to land
(`--wait 0` restores submit-and-return). `applied: false` still means "running", not failed, and comes with
`next_command`: a read-only `hs clip wait --pid ... --op ...` that confirms it later.
`hs wait` reports `retry_after_s` and `retry_after_ms` (the same value in seconds and milliseconds).

### Breaking changes in this release

Anything that only checks `!= 0` keeps working. Scripts that branch on specific exit codes, read
`hs make` output line by line, or run clip edits without a terminal should check the following.

**Exit codes.** Before, every failure was `1` (`4` in `hs make`, which also used `5` for
`REPAIR_STALLED` / `REPAIR_TIME_LIMIT` and `6` for credits). Now:

| Error | Before | Now |
|---|---|---|
| `INSUFFICIENT_POINTS`, `VIP_REQUIRED`, `DAILY_LIMIT` outside `hs make` | `1` | `6` (unchanged in `hs make`) |
| `MEMBERSHIP_OR_LIMIT_REQUIRED` (new) | — | `6` |
| `NO_CREDENTIAL`, `CREDENTIAL_EXPIRED`, `NOT_LOGGED_IN`, `CSRF_FAILED` | `1` / make `4` | `8` |
| `NOT_LOGGED_IN` with `suggested_action: "retry"` | `1` / make `4` | `75` |
| `ACCOUNT_RESTRICTED` | `1` / make `4` | `9` |
| `WRITE_OUTCOME_UNKNOWN`, `CREATE_OUTCOME_UNKNOWN`, `*_UNCERTAIN` with `retryable: false` | `1` / make `4` | `7` |
| `RATE_LIMITED`, `NETWORK_ERROR`, `STREAM_IDLE`, `DOWNLOAD_TIMEOUT`, `CLIP_BUSY`, `CALL_BUDGET_EXHAUSTED`, retryable `HTTP_ERROR`, `*_UNCERTAIN` with `retryable: true` | `1` / make `4` | `75` |
| `RUN_CONCURRENCY_LIMIT` | `1` / make `4` | `75` / make `5` |

`4` in `hs make` now only covers failures not listed above. `0`, `2`, and `hs make`'s `5` / `6`
keep their meaning.

**Clip edits wait when there is no terminal.** Without a terminal or with `--json`, clip edits now
wait up to 30 seconds for the change to land instead of returning at once. `--wait 0` restores the
old behaviour.

**`hs make` announces the project on standard error.** The `hs.created` line is written to
standard error; standard output is still exactly one JSON document. Take the pid from that line, or
from `pid` / `resume` in the final result.

**Extra fields.** JSON objects may carry `update: {latest, command}` when a newer hs is known
locally; `hs wait` adds `needs_action`, `still_running`, `retry_after_s`, `retry_after_ms` and
`next_commands`. Scripts that compare the full key set should allow them.

**Longer waits.** Commands wait for the account's allowance for up to `HS_RATE_LIMIT_WAIT` seconds
(default now 900, was 30). `hs plan confirm` and `hs chat send` wait up to `--wait` seconds (default
600) for a free task slot. `hs make` stops with exit code `5` after `--stall-timeout` (default 1800
seconds) with no visible change, and `hs wait` returns at once when a question or a storyboard needs
you, whatever `--until` says. See the release notes for the full list.

## Control-flow rules

1. Nothing in `hs` asks "are you sure". Four commands cannot be undone
   (`plan confirm` · `project rm` · `fast on` while queued · `publish --submit`): check with the
   person **before** running them. The read-only commands in `hs help account` show what each
   would do or cost. Two more spend credits that are not refunded even though the result can be
   reverted from a checkpoint: `settings voice` once production has started (`--cost` quotes it) and
   `material add` / `chat send --attach` with a file or URL (`material price` quotes it).
2. `applied: false` means a clip operation is still running, not that it failed; run its `next_command`.
3. `timed_out: true` from `hs wait` means call it again.

See `hs help json`, `hs help errors`, and `hs help batch` for the complete contract.

## IDs

Projects use a 15-digit `pid`. Clips accept a human-friendly position or a stable 9-digit `clip_id`.
Positions change when clips are added, removed, split, or merged; automation should prefer `clip_id`.



## Recovery and progress (advanced)

Defaults need no tuning. These interfaces remain available for automation and existing scripts; ordinary creation does not require setting them.

`--max-questions` limits answers only; storyboard approval does not consume it. `--max-continuations` defaults to 3 additional production prompts after approval, saved locally across restarts. At `CONTINUATION_LIMIT`, the project is preserved: inspect its conversation before explicitly raising the limit.

`PLAN_CONTINUATION_UNCERTAIN` means a continuation may have been accepted. Inspect `hs chat history --pid <pid>` and `hs project show --pid <pid>`; do not blindly resend. Progress polling and queue waiting do not consume attempts.

`REPAIR_CONTINUATION_UNCERTAIN` means a repair was dispatched but progress is unconfirmed. The CLI preserves its attempt budget across restarts and will not submit another repair for the same unresolved run. Inspect project status and chat history before intervening.

Repair recovery uses `--max-stalled-repairs` (default 3 consecutive completed rounds without additional finished scenes) and `--max-repair-seconds` (default 3600 seconds of active make observation, excluding time between invocations), alongside the total `--max-repairs` limit. Counts survive restarts. Queued and running work is awaited, not counted as a failed round. `REPAIR_STALLED` and `REPAIR_TIME_LIMIT` stop further automatic repair requests; inspect the unfinished scenes before raising limits.

`HS_PROGRESS=1 hs make ... --json` emits versioned `hs.progress` JSON events on stderr while stdout remains one final result. These events report observed progress; they are not a server push subscription.

`REPAIR_CONTINUATION_UNCERTAIN` preserves an unverified repair and includes a conversation inspection command. Explicit account or quota rejections release it for a later retry; a lost response never authorizes a second repair. Answers differ: Huasheng accepts at most one answer per question batch, so after a lost response the next attempt sends the answer again. `ANSWER_CONTINUATION_UNCERTAIN` means an answer was accepted (or a resend was refused because an earlier one landed) but the question has not moved on yet — wait, do not answer again. `hs make` keeps waiting in that case instead of stopping. `REPAIR_STALLED` and `REPAIR_TIME_LIMIT` exit with code 5 and print a resume command with a higher exhausted limit. Inspect the project before using it. Successful completion clears the repair recovery window.
