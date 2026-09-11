# Scripting and automation

[简体中文](automation.zh.md) · **English**

This page covers stable use from scripts, CI, and batch jobs. For interactive use, see the
[main README](../README.md).

## JSON output

Add `--json` to any command. Field names use `snake_case`.

```console
$ hs project show --json
{"pid": 123456789012345, "state": "READY", ...}
```

Failures use one envelope:

```json
{
  "error": {
    "code": "INSUFFICIENT_POINTS",
    "message": "...",
    "retryable": false,
    "suggested_action": "topup",
    "next_command": "hs make --pid ... --mode mg"
  }
}
```

- `suggested_action` is one of `login` · `topup` · `retry` · `null`
- `next_command` appears only when there is a command you can actually run
- Normal exit codes: `0` success, `1` command failure, `2` usage error
- `hs make`: `0` finished, `4` failed, `5` safety limit, `6` insufficient credits

## Control-flow rules

1. Nothing in `hs` asks "are you sure". Four commands cannot be undone
   (`plan confirm` · `project rm` · `fast on` while queued · `publish --submit`): check with the
   person **before** running them. The read-only commands in `hs help account` show what each
   would do or cost. Two more spend credits that are not refunded even though the result can be
   reverted from a checkpoint: `settings voice` once production has started (`--cost` quotes it) and
   `material add` / `chat send --attach` with a file or URL (`material price` quotes it).
2. `applied: false` means a clip operation is still running, not that it failed.
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
