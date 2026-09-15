# Sign-in, privacy, and system requirements

[简体中文](security.zh.md) · **English**

For installation and usage paths, see the [main README](../README.md).

## Sign-in and local files

`hs auth login` opens Bilibili's authorization page. Passwords, SMS codes, and risk checks stay in
the browser; `hs` never receives your password. On a machine without a browser, `hs auth login
--no-browser` lets you approve on another device and paste back the address the browser lands on.
The saved session is renewed automatically when fewer than 7 days are left.

| File | Contents | Notes |
| :--- | :--- | :--- |
| `~/.hs/credentials.json` | Sign-in credentials (mode `0600`) | Shared by CLI and MCP clients; removed by `hs auth logout` |
| `~/.hs/device.json` | A random-looking device id sent with sign-in, renewal and sign-out (mode `0600`) | Kept so the id stays the same when a container is rebuilt |
| `~/.hs/state.json` | Current pid and resume state | Contains no credentials; survives `hs auth logout` |
| `~/.hs/state.json.workflow.sqlite` | Per-project recovery records for `hs make` and answers (which submission is pending or accepted, repair counts) | Contains no credentials; prevents duplicate submissions after a restart |
| `~/.hs/state.json.requests.sqlite` | Request diagnostics: method, path, pid, run id, status and error codes, timing | Never stores request bodies, cookies or headers; keeps the latest 100,000 events; `HS_DIAGNOSTICS=0` turns it off. Stays on this machine |

Use `HS_CREDENTIALS_FILE` and `HS_STATE_FILE` to change these paths in CI or containers.

## Network and observable metadata

`hs` connects only to Huasheng and the Bilibili sign-in/publishing endpoints required for your
request. It has no separate telemetry channel. The one exception is an update check: at most once a
day, when you run a command or when an AI client starts `hs mcp serve`, it fetches the latest
release number from GitHub (`api.github.com`, `github.com`) and the npm registry (`registry.npmjs.org`,
`registry.npmmirror.com`), sending only the hs version in `User-Agent`, and mentions it if a newer one
exists. It never downloads or installs anything by itself; only `hs upgrade` does, from the GitHub
release of that version, after checking its SHA256. `hs upgrade` installs the highest version whose
GitHub release already has both the package and `SHA256SUMS` (a version that is on npm but whose
GitHub files are still uploading is skipped).

The checksum only protects against a broken or incomplete download. `SHA256SUMS` comes from the same
place as the package: with `HS_BASE_URL` pointing at a mirror, that mirror supplies both, so a
tampered mirror can serve a matching package and checksum. Releases are not signed yet; only point
`HS_BASE_URL` at a mirror you trust.
`HS_NO_UPDATE_CHECK=1` disables the check.
Normal requests include version, CLI/MCP mode, platform, and command name in `User-Agent`; they do
not include scripts, titles, pids, filenames, or footage contents. It looks like this:

```text
hs/<version> (cli; darwin-arm64; project create)
hs/<version> (mcp; darwin-arm64; huasheng_create_project)
```

Scripts, narration recordings, and footage are uploaded to Huasheng to make the video. Only
`hs publish --submit` publishes content publicly.

## Requirements

- macOS 11 or later (Apple Silicon or Intel)
- Linux with glibc 2.31 or later
- Windows 10 or later, x64; Windows on ARM uses x64 emulation

