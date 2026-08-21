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

## Choose how you want to use it

There is one `hs` binary with two ways to run it:

```text
                         one hs binary
                              │
                ┌─────────────┴─────────────┐
                │                           │
          you run hs commands       AI runs hs mcp serve
                │                           │
             hs CLI                 hs MCP server
                                            │
                                ┌───────────┴───────────┐
                                │                       │
                         desktop AI clients       terminal AI clients
                          interactive cards         complete text
```

`hs mcp serve` is not another product and needs no separate installation. It lets an AI client
launch the same `hs` binary with the same sign-in state.

| What you want | Follow this path | How you interact |
| :--- | :--- | :--- |
| Talk to AI and use visual timelines, previews, and footage cards | [Desktop AI clients](#desktop-ai-clients) | Chat and click cards in ChatGPT or Claude |
| Talk to a coding agent in your terminal | [Terminal AI clients](#terminal-ai-clients) | Chat in Codex CLI or Claude Code |
| Run exact commands, scripts, or batch jobs | [Use hs CLI directly](#use-hs-cli-directly) | Run `hs make`, `hs clip`, and other commands |

All three paths share one prerequisite: install `hs`, then sign in once.

## Step 1: install and sign in

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

### Sign in once

After installation, authorize and verify the `hs` binary:

```bash
hs auth login
hs account       # a credit balance confirms installation and sign-in
```

Every path shares `~/.hs/credentials.json`. The CLI, ChatGPT, Claude, and Codex do not need
separate sign-ins.

## Desktop AI clients

Choose this path to create through conversation while viewing and operating visual cards. The
desktop client launches `hs mcp serve` in the background; do not run it yourself.

### ChatGPT Desktop App

The ChatGPT desktop app can run the local `hs` MCP server directly and render the timeline,
per-clip previews, and the alternative-footage grid.

1. Open **Settings → MCP servers → Add server**
2. Enter `huasheng` as the name and choose **STDIO**
3. For Command, paste the full path printed by `which hs` on macOS/Linux or `where hs` on Windows
4. Add `mcp` and `serve` as the two arguments, save, then select **Restart**
5. Open a new conversation and type `/mcp` to confirm that `huasheng` is connected

> The ChatGPT Desktop App and Codex CLI share `~/.codex/config.toml`. Configure it here once
> and Codex CLI is ready too. See the [OpenAI MCP documentation](https://developers.openai.com/codex/mcp).

### Claude Desktop App

Claude Desktop can render the same Huasheng interactive cards.

1. Download **[huasheng.mcpb](https://github.com/superlcr/huasheng-cli/releases/latest/download/huasheng.mcpb)**
2. **Double-click** it. Claude Desktop opens an install dialog — click Install
3. It asks where `hs` lives. The default `~/.local/bin/hs` is already filled in, so just confirm

> **Why it still asks for a path**: Claude Desktop does not read your shell PATH.
> If you installed somewhere else, run `which hs` (`where hs` on Windows) and paste that.
> The bundle is unsigned, so the first install shows a warning — continue past it.

### Using the desktop client

Open a new conversation and ask:

> How many credits do I have left in Huasheng?

Then try:

> Make me a 30-second video about why the sky is blue

Projects, clips, settings, history, footage selection, and export appear as interactive cards.
Approving a storyboard spends credits; publishing goes public. The client asks before either action.

## Terminal AI clients

Choose this path if you already work with a coding agent in the terminal. The agent still calls
Huasheng through `hs mcp serve`, but presents complete text and structured results instead of cards.

### Codex CLI

```bash
codex mcp add huasheng -- hs mcp serve
codex mcp list
```

If you already added `huasheng` in the ChatGPT Desktop App, do not add it again. Use `/mcp`
inside Codex to check the connection.

### Claude Code CLI

```bash
claude mcp add --scope user huasheng -- hs mcp serve
claude mcp list
```

> Codex CLI and Claude Code CLI do not render the Desktop interactive cards, but they receive
> the same tools' complete text and structured results, so the full core workflow still works.

### Using the terminal agent

In Codex or Claude Code, simply ask:

> List my recent Huasheng projects

> Make the narration in clip 2 shorter

Do not run `hs mcp serve` manually. The `mcp add` configuration starts it when needed.

### Any other MCP client

Anything that speaks MCP works with this snippet:

```json
{"mcpServers": {"huasheng": {"command": "hs", "args": ["mcp", "serve"]}}}
```

## Use hs CLI directly

This path does not involve an AI client. Run `hs` yourself for automation, batch jobs, or precise
control over each step.

One command creates and downloads a finished video:

```bash
hs make --script "Three little-known facts about West Lake" --yes --out ./out.mp4
```

`--yes` means you approve the credit charge when the storyboard is confirmed. For step-by-step
control, see the [hs CLI guide](docs/cli.en.md). For scripts and batch jobs, see
[Scripting and automation](docs/automation.en.md).

## One creation lifecycle

Commands from you and actions from AI clients drive the same project lifecycle:

```
create → PLANNING
       → PAUSED       agent is waiting on you
       → PLANNING
       → PLAN_READY   plan ready for confirmation
       → PRODUCING    rendering clip by clip
       → READY        finished video available
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

AI clients ask when an answer or confirmation is required. CLI users can learn how to move through
these states in the [hs CLI guide](docs/cli.en.md).

## Read more

- [hs CLI guide](docs/cli.en.md): step-by-step creation, states, and command groups
- [Scripting and automation](docs/automation.en.md): JSON, exit codes, batch control, and IDs
- [Sign-in, privacy, and requirements](docs/security.en.md): credentials, network boundaries, platforms

## Safety boundaries

- The CLI and every AI client share one local credential; `hs` never receives your Bilibili password.
- Approving a storyboard spends credits, and publishing goes public. Both require your confirmation.
- Scripts and footage are uploaded to Huasheng for video creation; there is no separate telemetry
  channel or background updater.

## Upgrading

```bash
hs upgrade
```

This simply re-runs the installer. `hs` performs **no** update checks and **no** silent
background updates.

## Feedback

Found a problem? Please open an
[issue](https://github.com/superlcr/huasheng-cli/issues) and include the output of
`hs --version` — it carries the commit and build time, which is the key to diagnosing anything.
