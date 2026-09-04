# Sign-in, privacy, and system requirements

[简体中文](security.zh.md) · **English**

For installation and usage paths, see the [main README](../README.md).

## Sign-in and local files

`hs auth login` opens Bilibili's authorization page. Passwords, SMS codes, and risk checks stay in
the browser; `hs` never receives your password.

| File | Contents | Notes |
| :--- | :--- | :--- |
| `~/.hs/credentials.json` | Sign-in credentials (mode `0600`) | Shared by CLI and MCP clients; removed by `hs auth logout` |
| `~/.hs/state.json` | Current pid and resume state | Contains no credentials |

Use `HS_CREDENTIALS_FILE` and `HS_STATE_FILE` to change these paths in CI or containers.

## Network and observable metadata

`hs` connects only to Huasheng and the Bilibili sign-in/publishing endpoints required for your
request. It has no separate telemetry channel and does not check for updates in the background.
Normal requests include version, CLI/MCP mode, platform, and command name in `User-Agent`; they do
not include scripts, titles, pids, filenames, or footage contents. It looks like this:

```text
hs/<version> (cli; darwin-arm64; project create)
hs/<version> (mcp; darwin-arm64; huasheng_create_project)
```

Scripts and footage are uploaded to Huasheng to make the video. Only
`hs publish --submit` publishes content publicly.

## Requirements

- macOS 11 or later (Apple Silicon or Intel)
- Linux with glibc 2.31 or later
- Windows 10 or later, x64; Windows on ARM uses x64 emulation

