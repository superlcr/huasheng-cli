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
    "code": "CONFIRM_REQUIRED",
    "message": "...",
    "retryable": false,
    "suggested_action": "confirm",
    "next_command": "hs plan confirm --pid ... --yes"
  }
}
```

- Normal exit codes: `0` success, `1` command failure, `2` usage error
- `hs make`: `0` finished, `3` waiting for approval, `4` failed, `5` safety limit, `6` insufficient credits

## Control-flow rules

1. Stop and ask a person on `CONFIRM_REQUIRED`; never add `--yes` automatically.
2. `applied: false` means a clip operation is still running, not that it failed.
3. `timed_out: true` from `hs wait` means call it again.

See `hs help json`, `hs help errors`, and `hs help batch` for the complete contract.

## IDs

Projects use a 15-digit `pid`. Clips accept a human-friendly position or a stable 9-digit `clip_id`.
Positions change when clips are added, removed, split, or merged; automation should prefer `clip_id`.

