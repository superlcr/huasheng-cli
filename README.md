<div align="center">

# hs · Huasheng CLI

**From one sentence to a finished, publishable video**

[![Release](https://img.shields.io/github/v/release/superlcr/huasheng-cli?style=flat-square&color=00a1d6)](https://github.com/superlcr/huasheng-cli/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](https://github.com/superlcr/huasheng-cli/releases/latest)

[简体中文](README.zh.md) · **English**

</div>

---

`hs` brings [Huasheng](https://www.huasheng.cn)'s video creation pipeline to the command line.
Give it a sentence or a script, and it handles storyboarding, narration, footage and
composition — producing a video you can export or publish directly. You can step in and
adjust at any point along the way.

**A single self-contained binary.** No Node, no Python, no runtime to install.
Every command supports `--json`, designed for scripts and AI clients.

## Step 1: install and sign in

Do this once, regardless of which client you use later.

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
it to `~/.local/bin` (`%LOCALAPPDATA%\Programs\hs` on Windows).

### With npm

If you already live in the Node ecosystem, or just want to try it without installing anything:

```bash
npx @superlcr/hs --help
npm install -g @superlcr/hs    # the command is still `hs`
```

The npm package contains a small launcher; the binary for your platform arrives as an optional
dependency, so nothing is downloaded or compiled at install time. It is the same binary as the
release above.

After installation, open a new terminal, sign in, and confirm that `hs` can read your credit balance:

```bash
hs auth login
hs account
```

The CLI and every AI client share `~/.hs/credentials.json`; you do not sign in separately.

<details>
<summary>Manual download instead of the installer</summary>

<br>

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

</details>

After installing and signing in, choose either path below. Both use the same `hs` binary and sign-in.

## Option 1: use hs CLI directly

Use this path for exact commands, scripts, or batch jobs. `hs make` can start from one sentence or
a complete script, run the creation workflow, wait for the finished video, and download it.

Create a video from one sentence:

```bash
hs make --script "Three little-known facts about West Lake" --yes --out ./out.mp4
```

Request an MG-style video:

```bash
hs make --script "Explain Song dynasty tea whisking in 30 seconds" --mode mg --yes --out ./tea.mp4
```

Read a long script from a file:

```bash
hs make --script @script.txt --yes --out ./video.mp4
```

`--yes` approves the credit charge when the storyboard is confirmed; without it, `hs` stops for
confirmation. See the [hs CLI guide](docs/cli.md) for parameters, step-by-step editing, resuming,
and exporting. See [Scripting and automation](docs/automation.md) for JSON, exit codes, and batches.

## Option 2: use hs through MCP in an AI client

`hs` includes an MCP server. Any AI client that supports local STDIO MCP can launch it with:

```json
{
  "mcpServers": {
    "huasheng": {
      "command": "hs",
      "args": ["mcp", "serve"]
    }
  }
}
```

This configuration simply tells the client to run `hs mcp serve` when Huasheng is needed. There is
no separate hs MCP package to install, and you should not keep the command running yourself. If the
client cannot find `hs`, replace `command` with the full path from `which hs` (`where hs` on Windows).

The following are setup examples for four common clients. For any other MCP client, enter the same
`command` and `args` in its MCP server settings.

### ChatGPT Desktop App

1. Open **Settings → MCP servers → Add server**
2. Enter `huasheng` and choose **STDIO**
3. Set Command to the full path to `hs`; add `mcp` and `serve` as the two arguments
4. Save and restart, then type `/mcp` and check that `huasheng` is connected

ChatGPT Desktop renders interactive timeline, preview, footage, and export cards. It shares
`~/.codex/config.toml` with Codex CLI, so this setup also enables hs there.

### Claude Desktop App

1. Download **[huasheng.mcpb](https://github.com/superlcr/huasheng-cli/releases/latest/download/huasheng.mcpb)**
2. Double-click it, then select Install in Claude Desktop
3. Confirm the path to `hs`; the default is `~/.local/bin/hs`

If you changed the install location, paste the full path from `which hs` (`where hs` on Windows).
Continue if the first install warns that the extension is unsigned. Claude Desktop also renders
interactive cards.

### Codex CLI

```bash
codex mcp add huasheng -- hs mcp serve
codex mcp list
```

Do not add it again if you already configured `huasheng` in ChatGPT Desktop; both read
`~/.codex/config.toml`. See the [OpenAI MCP documentation](https://developers.openai.com/codex/mcp).

### Claude Code CLI

```bash
claude mcp add --scope user huasheng -- hs mcp serve
claude mcp list
```

Both commands run in the same terminal where you just signed in, so plain `hs` resolves; if your
shell cannot find it, substitute the full path from `which hs` (`where hs` on Windows). Codex CLI
and Claude Code present complete text results instead of desktop interactive cards.

### Use it through conversation

After setup, say in your AI client:

> Make me a 30-second video about why the sky is blue

You can inspect and refine existing projects too:

> List my recent Huasheng projects

> Make the narration in clip 2 shorter

> Replace clip 3 with more futuristic footage

Confirming a storyboard spends credits, and publishing makes the video public. The client asks
before either action.

## More documentation

- [hs CLI guide](docs/cli.md): step-by-step creation, states, and command groups
- [Scripting and automation](docs/automation.md): JSON, exit codes, batch control, and IDs
- [Sign-in, privacy, and requirements](docs/security.md): credentials, network boundaries, platforms

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
