# hs CLI guide

This page is for people who run `hs` commands directly. For installation, sign-in, and AI client
setup, see the [main README](../README.en.md).

## Make a complete video

```bash
hs make --script "Three little-known facts about Hangzhou's West Lake" --yes --out ./out.mp4
```

`hs make` answers the agent's questions, approves the storyboard, waits for production, and downloads
the result. `--yes` is required because approving a storyboard spends credits. A file works too:
`--script @script.txt`.

## Control each step

```bash
hs project create --script "…"   # create a project and get its pid
hs use <pid>                     # remember the current project
hs wait                          # wait for the next decision
hs chat answer "Choose option B"
hs plan show --cost
hs plan confirm --yes            # spends credits
hs clip ls
hs clip edit --clip 3 --text "…"
hs settings
hs export get --out ./out.mp4
hs publish --submit --title "…"  # publishes to Bilibili
```

## Project states

```text
create → PLANNING
       → PAUSED       waiting for your answer       → hs chat answer
       → PLANNING
       → PLAN_READY   waiting for your approval     → hs plan confirm --yes
       → PRODUCING
       → READY        ready to export or publish
```

`hs wait` stops at `PAUSED`, `PLAN_READY`, `READY`, or `FAILED`. Every command also returns
`next_actions` to tell you what can happen next.

## Command groups

| Command | Purpose |
| :--- | :--- |
| `hs auth` | Sign in, check status, or sign out |
| `hs account` | Check credits |
| `hs make` | Turn a prompt or script into a complete video |
| `hs project` | Create, inspect, list, or delete projects |
| `hs use` | Remember the current project |
| `hs wait` | Wait for the next decision |
| `hs plan` | Inspect or approve the storyboard |
| `hs chat` | Answer questions, give directions, inspect events |
| `hs clip` | Edit narration, structure, footage, and subtitles |
| `hs settings` | Aspect ratio, voice, speed, subtitles, and BGM |
| `hs voice` | List voices |
| `hs pref` | Manage personal creative preferences |
| `hs material` | Register and organize footage |
| `hs mg` | Show or hide motion graphics |
| `hs snapshot` | Save, undo, and redo project state |
| `hs export` | Download a finished video |
| `hs publish` | Publish to Bilibili (**goes public**) |
| `hs fast` | Use the priority lane |
| `hs mcp` | Run as an MCP server for AI clients |
| `hs upgrade` | Upgrade to the latest release |

Use `hs --help` for the overview and `hs help <command>` for parameters, outputs, errors, and examples.

