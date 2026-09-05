# hs CLI guide

[简体中文](cli.zh.md) · **English**

This page is for people who run `hs` commands directly. For installation, sign-in, and AI client
setup, see the [main README](../README.md). For `--json`, exit codes, and batch jobs, see
[Scripting and automation](automation.md).

Every command here also accepts `--json`, and `hs help <command>` prints the full reference for
one command — parameters, output shape, error codes, and examples.

## Quick start: one command

```bash
hs make --script "Three little-known facts about Hangzhou's West Lake" --out ./out.mp4
```

`hs make` runs the whole workflow for you: it answers the agent's questions, approves the
storyboard, waits through production, and downloads the finished file.

```bash
hs make --script @script.txt --out ./video.mp4              # a script from a file
hs make --audio ./narration.m4a --out ./video.mp4              # your recording is the narration
hs make --script "Song dynasty tea whisking" --mode mg      # motion graphics, not footage
hs make --pid 123456789012345                               # resume where it stopped
```

`--mode` picks how the video is built: `clip` cuts from footage, `mg` adds motion graphics, and
`auto` (the default) lets Huasheng decide.

**`hs make` approves the storyboard for you, and that spends credits.** That is what "one
command" means; it prints what the approval cost. To read the storyboard and its price before
anything is charged, take the long way round below — `hs make --pid <pid>` picks up from
wherever you stopped. If `make` stops anywhere, it prints the exact command that continues from
that point — copy that line rather than re-running your original one.

## The long way round: step by step

`hs make` is those steps in a loop. Run them yourself when you want to read the storyboard,
rewrite narration, or change the look before paying for production.

**1. Sign in once.** The CLI and every AI client share `~/.hs/credentials.json`.

```bash
hs auth login
hs account          # a credit balance confirms you are signed in
```

**2. Start a video and remember it.** `hs use` saves the project id so every later command can
drop `--pid`.

```bash
hs project create --script "Three little-known facts about Hangzhou's West Lake"
hs project create --audio ./narration.m4a                      # audio mode; add --transcript @words.txt if you have it
hs use 123456789012345
```

**3. Wait for Huasheng to need you.** It plans on its own and stops when it has a question or a
storyboard. `hs wait` blocks until one of those happens.

```bash
hs wait                        # returns at PAUSED, PLAN_READY, READY, or FAILED
hs chat answer "Keep it light and fast"
```

`hs chat send` gives a direction at any time, not only when asked. Attach `--clip 3` or
`--animation 2` when “this” should mean one exact storyboard item; omit both for a project-wide
request. `hs chat history` shows what has been said so far.

```bash
hs chat send --clip 3 "find a calmer shot for this narration"
hs chat send --animation 2 "make this MG animation more concise"
```

**4. Read the storyboard before paying.**

```bash
hs plan show --cost            # what it will make, and what it will cost
hs plan confirm                # spends credits, starts production — and says how many
```

**5. Adjust the clips.** Production renders clip by clip; you can rework any of them.

```bash
hs clip ls                                   # every clip with length and footage
hs clip show --clip 3                        # full narration and the footage in use
hs clip edit --clip 3 --text "New narration"
hs clip split --clip 3 --at 2                # cut clip 3 after its second line
hs clip candidates --clip 3                  # other footage for this clip
hs clip pick --clip 3 --candidate 2
```

**6. Set the look and sound.** Run `hs settings` with no arguments to see everything, or name one
item to be told what it accepts.

```bash
hs settings                                  # every item and its current value
hs settings bgm                              # what this one accepts
hs settings aspect 9:16
hs settings subtitle-size 42
```

**7. Deliver it.**

```bash
hs export get --out ./out.mp4                # download the finished video
hs publish --title "West Lake"               # shows exactly what would be posted; posts nothing
hs publish --submit --title "West Lake"      # post it to Bilibili — this is public
```

`hs publish --submit` is the only command that makes anything public.

## Project states

```text
create → PLANNING
       → PAUSED       waiting for your answer       → hs chat answer
       → PLANNING
       → PLAN_READY   waiting for your approval     → hs plan confirm
       → PRODUCING
       → READY        ready to export or publish
```

| State | What it means | What to do |
| :--- | :--- | :--- |
| `QUEUED` | Waiting in line | `hs fast on` skips the queue |
| `PLANNING` | Huasheng is thinking or working | Wait |
| `PAUSED` | **It asked you something** | `hs chat answer "…"` — but if it is asking you to approve the plan, `hs plan confirm` |
| `PLAN_READY` | Storyboard ready; nothing has been charged yet | `hs plan show --cost`, then `hs plan confirm` |
| `PRODUCING` | Rendering clip by clip | Wait, or edit clips that are already done |
| `READY` | Finished | `hs export get` or `hs publish` |
| `FAILED` | Something went wrong | `hs project show` explains why in `reason` |

`hs wait` stops at `PAUSED`, `PLAN_READY`, `READY`, and `FAILED`. Every command also returns
`next_actions`, which names what can happen from where you are.

## Command reference

Anything below that takes `--pid` can omit it once you have run `hs use <pid>`.

### Sign in and account

| Command | What it does |
| :--- | :--- |
| `hs auth login` | Sign in with your Bilibili account, in the browser |
| `hs auth status` | Whether the saved session still works |
| `hs auth refresh` | Renew the session without signing in again |
| `hs auth logout` | Forget the saved credentials |
| `hs account` | Your credit balance, batch by batch, with expiry dates |

### Start and track a video

| Command | What it does |
| :--- | :--- |
| `hs project create --script <text\|@file>` | Start a video and print its `pid` |
| `hs project create --audio <file\|url> [--transcript <text\|@file>]` | Audio mode: your own narration recording (a file, or a public URL) instead of `--script`. The transcript is optional — leave it out and Huasheng transcribes the recording. `hs` uploads the file itself |
| `hs project show [--pid <pid>]` | State, settings, and what can happen next |
| `hs project ls [--limit 20]` | Your recent videos |
| `hs project rm --pid <pid>` | Delete one — at once, and it cannot be undone |
| `hs use <pid>` / `hs use` / `hs use --clear` | Remember, show, or forget the current video |
| `hs wait [--until any\|plan\|paused\|done] [--timeout 60]` | Block until Huasheng needs a decision |
| `hs make …` | All of the above in one command — see the quick start |

### Talking to Huasheng

| Command | What it does |
| :--- | :--- |
| `hs chat answer <answer\|@file> [--no-wait]` | Answer the question it is waiting on |
| `hs chat send [--clip N \| --animation N] <message\|@file>` | Give a direction, optionally about one exact item |
| `hs chat cancel` / `hs chat retry` / `hs chat clear` | Stop the current run, run it again, or clear the thread |
| `hs chat history [--limit 20]` | What has been said so far |
| `hs chat watch [--timeout 300]` | Follow along while it works |
| `hs chat cost [--run <run_id>]` | What one run cost |

### Storyboard and production

| Command | What it does |
| :--- | :--- |
| `hs plan show [--cost]` | The storyboard, and the price with `--cost` |
| `hs plan confirm` | Approve it — **this spends credits and cannot be undone** |
| `hs fast` / `hs fast on` / `hs fast off` | Check, join, or leave the priority lane (`hs fast` shows what skipping costs; once queued, `on` is one-way) |

### Editing clips

| Command | What it does |
| :--- | :--- |
| `hs clip ls` | Every clip: length, footage, first line of narration |
| `hs clip show --clip <#>` | One clip in full |
| `hs clip edit --clip <#> --text "…"` | Rewrite the narration |
| `hs clip add --text "…" [--after <#>\|--before <#>]` | Insert a new clip |
| `hs clip rm --clip <#>` | Remove one |
| `hs clip split --clip <#> --at <line>` | Split after a line of narration |
| `hs clip merge --clip <#> --into <#>` | Merge two clips |
| `hs clip retry --clip <#>` | Rebuild a clip that failed |
| `hs clip dub --clip <#> [--undo]` | Re-record the voice for one clip |
| `hs clip candidates --clip <#> [--like <uuid>]` | Other footage for this clip |
| `hs clip pick --clip <#> --candidate <#\|uuid>` | Use one of them |
| `hs clip srt [--out <file>]` | Export subtitles as SRT |

### Look and sound

`hs settings` with no value tells you what an item accepts; for voices and music it fetches the
current list.

| Item | Accepts |
| :--- | :--- |
| `aspect` | `16:9` or `9:16` |
| `voice` | A narrator voice, by id or name (`hs voice ls` lists them) |
| `speed` | Speaking pace, 1.0 to 2.0 |
| `name` | What this video is called |
| `subtitle` | on / off |
| `subtitle-size` | 22 / 32 / 42 / 54 (a preset also sets the matching outline) |
| `subtitle-color` | `#text/#outline`, or a preset name |
| `subtitle-outline` | Outline thickness, 1 to 200 |
| `bgm` | A track name, an id, or `off` |
| `bgm-volume` | 1 to 100 — to silence it use `bgm off` |
| `voice-volume` | 0 to 100 |
| `auto-dub` | Re-record the voice after you rewrite narration: on / off |
| `sync` | Re-search footage after you rewrite narration: on / off |

There are around 150 stock voices, plus any voice you cloned on the website. Each one has a
name and a short description of how it sounds, so narrow the list instead of scrolling it:

```bash
hs voice ls                       # all of them, with the default marked
hs voice ls --search <text>       # match on the name, the sound, or the id
hs voice ls --json                # adds preview_url, to listen before choosing
```

Anywhere a voice is asked for, an id or a name works, and part of a name is enough as long as
it matches exactly one voice. If it matches several, `hs` lists them and asks you to pick by
id — it will not guess, because the wrong voice means re-recording the whole video.

Changing the voice does not re-record clips you already have, and changing the pace does not
re-render them. `hs` says so each time, and tells you how to apply the change to a clip you
care about.

`hs mg ls` / `hs mg show <id>` / `hs mg hide <id>` show or hide motion graphics. Their content is
not editable from the CLI.

### Your own footage and preferences

| Command | What it does |
| :--- | :--- |
| `hs material ls [--folder <id>] [--limit 20]` | Your footage library |
| `hs material add <file\|url\|id …> [--name …] [--duration …] [--folder <id>]` | Add footage: files on this machine, public URLs, or ids of files sent while editing. Huasheng reads video before it can pick it, charged by the second; images are free |
| `hs material price <file\|url\|id …>` | What `add` would cost for the same files, without adding anything |
| `hs material ls --uploads` | Files you sent while editing (never read; `add <id>` reads one into the library) |
| `hs material rm <id,…>` | Remove footage |
| `hs material mkdir <name>` | Make a folder |
| `hs material mv <id,…> --to <folder id>` | Move footage into one |
| `hs material rename <folder id> <new name>` | Rename a folder |
| `hs material rmdir <folder id>` | Remove a folder |
| `hs pref ls` / `hs pref show <id>` | Style preferences, which belong to you rather than to one video |
| `hs pref add "name" "text"` / `hs pref edit <id>` / `hs pref rm <id>` | Manage them |
| `hs voice ls [--search <text>]` | Narrator voices available before a video exists |

Offering footage with `--material` or `--folder` does not force Huasheng to use it.

### Undo, deliver, and the rest

| Command | What it does |
| :--- | :--- |
| `hs snapshot ls` | Points you can go back to |
| `hs snapshot undo` / `hs snapshot redo` / `hs snapshot goto <s-number>` | Move between them |
| `hs export start [--watermark]` / `hs export status --task <id>` / `hs export get [--out <file>] [--timeout 300]` | Render and download the finished video |
| `hs publish [--title …] [--tag …] [--cover …]` | The upload page link, and exactly what `--submit` would post |
| `hs publish --submit [--title …] [--tag …] [--cover …]` | Post it to Bilibili — **this makes it public and cannot be undone** |
| `hs mcp serve` | Run as an MCP server so an AI client can use Huasheng |
| `hs upgrade` | Re-run the installer to get the latest release |

## Global options and environment

| Option | Meaning |
| :--- | :--- |
| `--json` | Structured output — see [Scripting and automation](automation.md) |
| `--pid <pid>` | Which video; `hs use <pid>` once and you can leave it out |
| `--no-color` | Plain text (`NO_COLOR` works too) |
| `--cookie <session>` | Override the saved sign-in, for development |

`HS_COOKIE`, `HS_HOST`, `HS_CREDENTIALS_FILE`, `HS_STATE_FILE`, `HS_PID_REQUIRED`, and
`HS_RATE_LIMIT_WAIT` override the same things from the environment.

## Credits and one-way steps

A command does what its verb says — including when that costs credits, which is normal here —
and says what it cost. Nothing asks "are you sure". Looking before you act is a separate,
read-only command:

| Before you… | Look with |
| :--- | :--- |
| `hs material add` | `hs material price <same files>` |
| `hs plan confirm` | `hs plan show --cost` |
| `hs fast on` | `hs fast` |
| `hs project rm` | `hs project show` |
| `hs publish --submit` | `hs publish` (same options, nothing posted) |

Four steps cannot be taken back: `hs plan confirm`, `hs fast on` while queued, `hs project rm`,
`hs publish --submit`. Most other steps are charged for the work Huasheng actually does, so they
cannot be priced in advance; `hs chat cost` shows what a round came to afterwards, and
`hs account` shows the balance.

An option `hs` does not know is an error, and nothing runs.

## Where to go next

- `hs help <command>` — the full reference for one command, including its JSON shape and errors
- `hs help ids` — how to point at a video or at one clip
- `hs help json`, `hs help errors`, `hs help batch` — the scripting contract
- [Scripting and automation](automation.md) — JSON, exit codes, batch control
- [Sign-in, privacy, and requirements](security.md) — credentials, network boundaries, platforms
