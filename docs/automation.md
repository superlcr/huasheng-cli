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
   would do or cost.
2. `applied: false` means a clip operation is still running, not that it failed.
3. `timed_out: true` from `hs wait` means call it again.

See `hs help json`, `hs help errors`, and `hs help batch` for the complete contract.

## IDs

Projects use a 15-digit `pid`. Clips accept a human-friendly position or a stable 9-digit `clip_id`.
Positions change when clips are added, removed, split, or merged; automation should prefer `clip_id`.

