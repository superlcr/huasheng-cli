<div align="center">

# hs · Huasheng CLI

**From one sentence to a finished, publishable video**

[![Release](https://img.shields.io/github/v/release/superlcr/huasheng-cli?style=flat-square&color=00a1d6)](https://github.com/superlcr/huasheng-cli/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](https://github.com/superlcr/huasheng-cli/releases/latest)

[简体中文](README.md) · **English**

</div>

---

`hs` brings [Huasheng](https://www.huasheng.cn)'s video creation pipeline to the command line.
Give it a sentence or a script, and it handles storyboarding, narration, footage and
composition — producing a video you can export or publish directly. You can step in and
adjust at any point along the way.

**A single self-contained binary.** No Node, no Python, no runtime to install.
Every command supports `--json`, designed for scripts and AI clients.

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.sh | sh
```

### Windows

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.ps1 | iex
```

The installer downloads the package for your platform, **verifies its SHA256**, and extracts
it to `~/.local/bin` (`%LOCALAPPDATA%\Programs\hs` on Windows). Open a new terminal afterwards.

### Manual download

Grab the package for your platform from
[Releases](https://github.com/superlcr/huasheng-cli/releases/latest), extract it, and place
the executable anywhere on your `PATH`:

| Platform | File |
| :--- | :--- |
| macOS · Apple Silicon | `hs-darwin-arm64.tar.gz` |
| macOS · Intel | `hs-darwin-x64.tar.gz` |
| Linux · x64 | `hs-linux-x64.tar.gz` |
| Windows · x64 | `hs-windows-x64.zip` |

Every release ships a `SHA256SUMS` file. **Verifying it is recommended:**

```bash
shasum -a 256 -c SHA256SUMS
```

> Both macOS packages are signed and notarized by Apple (Developer ID Application).
> The Windows package is unsigned; SmartScreen may prompt on first run — choose
> "More info → Run anyway".

## Quick start

```bash
hs auth login                    # Sign in via browser
hs account                       # Check your credit balance
```

**One command, one finished video:**

```bash
hs make --script "Three little-known facts about West Lake" --yes --out ./out.mp4
```

`hs make` runs the whole pipeline — answering the agent's questions, confirming the plan,
waiting for rendering, and downloading the result. `--yes` must be given explicitly, because
confirming a plan **spends credits and cannot be undone**; without it, `hs make` stops at the
quote and waits for you.

`--script` also accepts a file: `--script @script.txt`.

## Step by step

To stay in control, walk the project through its lifecycle:

```bash
hs project create --script "…"   # Create a project, get a pid
hs use <pid>                     # Remember it — no more --pid on every command

hs wait                          # Wait until a decision is needed
hs chat answer "the second one"  # Answer the agent's question
hs plan show --cost              # Review the storyboard and its cost
hs plan confirm --yes            # Start rendering (★ spends credits)

hs clip ls                       # List all clips
hs clip edit --clip 3 --text "…" # Rewrite the narration of clip 3
hs settings                      # List every presentation setting
hs settings subtitle-size 42     # Set one; likewise aspect / voice / speed / bgm…

hs export get --out ./out.mp4    # Export locally
hs publish --submit --title "…"  # Publish to Bilibili
```

### Project lifecycle

```
create → PLANNING
       → PAUSED       agent is waiting on you       → hs chat answer
       → PLANNING
       → PLAN_READY   plan ready for confirmation   → hs plan confirm --yes
       → PRODUCING    rendering clip by clip
       → READY        finished video available      → hs export / hs publish
```

| State | Meaning |
| :--- | :--- |
| `QUEUED` | Queued (`hs fast` can skip the line) |
| `PLANNING` | The agent is thinking or working |
| `PAUSED` | **Waiting for your answer** |
| `PLAN_READY` | Plan ready; credits are spent only on confirmation |
| `PRODUCING` | Rendering |
| `READY` | Ready to export or publish |
| `FAILED` | Failed — see `reason` in `hs project show` |

`hs wait` blocks until one of `PAUSED` / `PLAN_READY` / `READY` / `FAILED` — these four are
**the only moments that need a decision from you**. Everything else is just waiting.

Every command's output includes `next_actions`, telling you what you can do next.

## Commands

| Command | Purpose |
| :--- | :--- |
| `hs auth` | Sign in / status / sign out |
| `hs account` | Credit balance (at zero, even a one-word edit is rejected) |
| `hs make` | **One-shot production**: a sentence in, a video out |
| `hs project` | Create / inspect / list / delete projects |
| `hs use` | Remember the current project, dropping `--pid` |
| `hs wait` | Block until the next decision point |
| `hs plan` | Review the storyboard / confirm production |
| `hs chat` | Talk to the agent: answer, request changes, read the event stream |
| `hs clip` | Clips: narration, add/remove, split/merge, footage, subtitles |
| `hs settings` | Per-project presentation: aspect, voice, speed, subtitles, BGM |
| `hs voice` | Available voices (pick before creating a project) |
| `hs pref` | Creative preferences (tied to **you**, not to a project) |
| `hs material` | Material library: register public assets, manage folders |
| `hs mg` | Motion-graphic segments: show / hide (content changes go through `hs chat`) |
| `hs snapshot` | Checkpoints: undo, redo, jump to before a given instruction |
| `hs export` | Export the finished video locally |
| `hs publish` | Publish to Bilibili (**the only command that goes public**) |
| `hs fast` | Fast lane, when the queue is not moving |
| `hs mcp` | Run as an MCP server, for AI clients |
| `hs upgrade` | Upgrade to the latest version |

Run `hs --help` for an overview, `hs help <command>` for full flags.

## For scripts and AI clients

Add `--json` to any command for a structured object. All fields are `snake_case`.

**On success**, the data is returned directly:

```console
$ hs project show --json
{"pid": 123456789012345, "state": "READY", ...}
```

**On failure**, a uniform error envelope:

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

- `suggested_action` ∈ `login` · `topup` · `retry` · `confirm` · `null`
- `next_command` appears only when there genuinely is a command you can copy and run

**Exit codes:** `0` success · `1` command failed (details in the `error` object on stdout) ·
`2` usage error.

> ⚠ **`hs make` has its own exit codes**, not the three above:
> `0` finished · `3` stopped at the quote (no `--yes`) · `4` failed · `5` hit a safety cap ·
> `6` out of credits. When running in bulk, `3` and `6` are not breakage — they mean
> "waiting for a human" and "waiting for a top-up". See `hs help make`.

### Three conventions worth internalizing

> **The right response to `CONFIRM_REQUIRED` is to ask the human** — not to retry with
> `--yes`. `next_command` is what the human copies *after* approving.
>
> **`applied: false` on a clip write is not a failure** — the work is still running in the
> background.
>
> **`timed_out: true` from `hs wait` is not a failure** — call it again and keep waiting.

See `hs help json` for the full contract.

### Plugging into an AI client (MCP)

`hs` ships an MCP server. Clients like Claude Desktop and Claude Code can launch it directly:

```json
{"mcpServers": {"huasheng": {"command": "hs", "args": ["mcp", "serve"]}}}
```

Credentials are **shared with the CLI** (`~/.hs/credentials.json`) — sign in once in your
terminal and the AI side just works. If you have not, the server still starts and walks you
through signing in.

MCP covers the **main line** (create → wait → answer → confirm → edit clips → export → publish),
not everything `hs` can do: adding/removing/splitting clips, the material library, creative
preferences and snapshots stay on the command line — they either need you to look at the picture
or are simply a person's job. Only `pid` crosses the boundary; internal ids and `clip_id` never
appear in tool inputs or outputs.

> 🔴 **Exactly two tools spend money or cannot be undone**: confirming the storyboard (charges
> credits) and publishing (goes public). Both are marked `destructiveHint`, so clients prompt for
> confirmation, and the cost is stated in the tool title. Every other write is checkpointed
> server-side and can be rolled back.

See `hs help mcp`.

### ⚠ Three kinds of id — don't mix them up

| id | Length | Notes |
| :--- | :--- | :--- |
| `pid` | 15 digits | Used by almost every command; `hs` accepts **only** `pid` externally |
| internal id | 7 digits | Needed by some endpoints; `hs` converts for you |
| `clip_id` | 9 digits | Clip level; `hs clip --clip` accepts both an index and a `clip_id` |

**The most common trap: in `hs project ls --json`, `id` is the internal id — `pid` is the
15-digit one.** Always read the `pid` field in scripts. See `hs help ids`.

## Credentials and privacy

`hs` acts on your Bilibili account, so here is exactly what that involves.

**How signing in works**: `hs auth login` opens your browser to Bilibili's authorization
page, where you sign in with a password, an SMS code or a QR scan and click "Authorize".
**`hs` never sees your password**, and any anti-fraud captcha is handled by the web page.
After you approve, the browser redirects back to a `127.0.0.1` callback port on your machine.

**Where things are stored**:

| File | Contents | Notes |
| :--- | :--- | :--- |
| `~/.hs/credentials.json` | Your credentials (plaintext, mode `0600`) | Valid 180 days; `hs auth logout` deletes it |
| `~/.hs/state.json` | The pid from `hs use`, resume args for `hs make` | No credentials; `logout` does **not** clear it |

`HS_CREDENTIALS_FILE` / `HS_STATE_FILE` relocate them (useful in CI or containers where
`$HOME` is not writable).

**What it connects to**: only Huasheng's service and Bilibili's sign-in / upload endpoints —
whatever the command you typed requires. **No separate telemetry channel, no background update
checks.** It does not reach the network unless you ran a command.

**What we can see**: the `User-Agent` on those requests carries four things — the version,
whether you are on the CLI or MCP, the platform, and **the command name itself**
(e.g. `project create`, `huasheng_create_video`):

```
hs/0.1.0 (cli; darwin-arm64; project create)
```

This is our only way of knowing which versions are still in use and worth maintaining. It rides
on requests that were going out anyway — nothing extra is sent. **Your content never appears in
it**: scripts, project titles, pids and filenames are all excluded, and the command name goes
through an allow-list that yields an empty string when it does not recognise the input.

**⚠ `logout` does not invalidate credentials that already leaked.** It ends this session;
a copy taken earlier still works. If your credentials leak, sign out of all devices and
change your password from Bilibili's account security page.

**⚠ Your scripts and assets are uploaded to Huasheng** to generate the video — the same as
creating on the Huasheng website. `hs publish --submit` is the **only** command that makes
anything public, and it requires an explicit `--yes`.

## Upgrading

```bash
hs upgrade
```

This simply re-runs the installer. `hs` performs **no** update checks and **no** silent
background updates.

## Requirements

- **macOS** 11 or later (native builds for both Apple Silicon and Intel)
- **Linux** glibc 2.31 or later (Ubuntu 20.04+, Debian 11+, CentOS Stream 9+)
- **Windows** 10 or later, x64; Windows on ARM runs through the system's x64 emulation layer

## Feedback

Found a problem? Please open an
[issue](https://github.com/superlcr/huasheng-cli/issues) and include the output of
`hs --version` — it carries the commit and build time, which is the key to diagnosing anything.
