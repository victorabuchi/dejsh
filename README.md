<div align="center">

# dejsh

### Give your shell a memory.

Learns how you fix errors, shows where you left off, turns what worked into scripts,<br>
and audits your history for wasted keystrokes, risky commands and leaked secrets.

[![CI](https://github.com/victorabuchi/dejsh/actions/workflows/ci.yml/badge.svg)](https://github.com/victorabuchi/dejsh/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash%203.2%2B-4EAA25?logo=gnubash&logoColor=white)
![Works with](https://img.shields.io/badge/works%20with-zsh%20%7C%20bash%20%7C%20fish-blue)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)
![Network](https://img.shields.io/badge/network-never-informational)

[Quick start](#quick-start) · [Features](#features) · [Install](#install) · [Privacy](#privacy) · [FAQ](#faq)

<br>

<img src="assets/demo.gif" alt="A real terminal session: git status fails, dejsh fix --run recalls that git init fixed it before and applies it on confirmation, git status then works, and dejsh fixes lists the learned fixes" width="820">

</div>

---

## Why dejsh

*dejsh* is "déjà vu" + "sh": that feeling of having seen this error before, except your shell actually remembers how you fixed it.

Your shell history is a record of everything you do, and it's nearly useless. It can't tell you **where** a command ran, **whether it failed**, or **how long it took**. So every day you re-solve errors you've already solved, retype commands you've typed a thousand times, and lose your place when you return to a project.

dejsh fixes that in two layers:

| Layer | What it is | Needs install? |
|---|---|---|
| **Audit** | Reads the history file you already have. Finds aliases worth making, recurring typos, secrets sitting in plaintext, risky commands, repeated workflows, bad habits. | No. Run it now. |
| **Memory** | An opt-in recorder adds exit code, duration and directory to each command. On top of that: personal error-fix memory, "where did I leave off", scripts from what just worked. | One command: `dejsh hook --install` |

It is a single bash script for zsh, bash and fish. No dependencies, no network access, and it writes nothing unless you ask.

## Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/victorabuchi/dejsh/main/install.sh | bash
dejsh                       # checkup: what's fixable on your machine
dejsh hook --install        # optional: turn on the memory layer, then open a new terminal
```

```console
$ dejsh

  DEJSH CHECKUP — 4,210 commands in ~/.zsh_history

  ✂  ALIASES  47 repeated commands could be aliases (~7,224 keystrokes)   → dejsh alias
  ✎  TYPOS    1 recurring typos                                           → dejsh typos
  🔑 SECRETS  4 possible secret(s) in plaintext!                          → dejsh leaks
  ⛓  FLOWS    13 workflows you repeat could be one command                → dejsh flows
  ☢  DANGER   2 risky command patterns in your history                    → dejsh danger
  🧭 COACH    1 habits costing you time                                   → dejsh coach
  🎙 MEMORY   not recording: unlock fix / resume / slow / safe scripts    → dejsh hook --install
  🔍 RECALL   find any past command by keywords                           → dejsh find <words>
  🪨 DIG      your history as rock layers                                 → dejsh dig
```

## Features

### Memory layer

Run `dejsh hook --install` once. The recorder appends one line per command to `~/.dejsh/journal.tsv`. These commands use it:

| Command | Solves |
|---|---|
| [`dejsh fix`](#dejsh-fix) | "That just failed. I know I've fixed this before." |
| `dejsh fixes` | "How do I usually fix things?" Your personal troubleshooting memory, including flaky commands that only needed a re-run. |
| [`dejsh resume`](#dejsh-resume) | "Where did I leave off in this project?" `--all` lists every project by recency. |
| [`dejsh script`](#dejsh-script) | "I need to repeat what I just did." |
| `dejsh slow` | "Where does my terminal time actually go?" |

#### `dejsh fix`

```console
$ dejsh fix

  last failure (2 min ago, in ~/projects/shopify)
    ✗ npm start  (exit code 1)

  Last time `npm start` failed, you ran:
    npm install   (worked 5 of 5 times)
```

It learns from your own failures. A failure followed by the commands you ran before it succeeded becomes a remembered fix. Nothing is hard-coded, so it works for your stack, your errors and your fixes.

Add `--run` to apply the remembered fix: `dejsh fix --run` shows the command, asks `[y/N]`, runs it in the directory where the failure happened, and tells you what to re-run. It never runs anything without asking, and only offers single-command fixes.

#### `dejsh resume`

```console
$ dejsh resume

  WHERE YOU LEFT OFF in ~/projects/dejsh
  last session 2 h ago · 6 commands over 43s

   ✓ git status
   ✓ shellcheck dejsh
   ✓ git commit -m docs
   ✗ git push origin main (exit 1)

  ⚠ you stopped on a failing command: git push origin main
  git: on main, 1 uncommitted change(s)
```

#### `dejsh script`

```console
$ dejsh script -n 5 > setup.sh

#!/usr/bin/env bash
# generated by dejsh from 5 command(s)
set -euo pipefail

cd "/Users/you/projects/dejsh"
git status
shellcheck dejsh
git add -A
git commit -m docs
```

Only commands that succeeded are included. Lines that look like they contain secrets are replaced with a comment. `--since 30m` limits by time and `-n N` by count. Without the recorder it falls back to plain history and says so.

### Audit layer

These work immediately, from your existing history file.

| Command | Solves | Output |
|---|---|---|
| `dejsh alias` | Retyping the same long commands | Ready-to-paste aliases ranked by keystrokes saved. Avoids names that clash with real commands or your existing aliases. Never suggests a command containing a secret. When the last argument varies (like `git commit -m "..."`), it suggests an alias for the stable part (`alias gcm='git commit -m'`) and marks it "add your argument". |
| `dejsh typos` | Mistyping `git`, `docker`, `kubectl` | A fix-alias for each recurring typo (`gti` → `git`). |
| `dejsh leaks` | A token or password pasted into a command once | Redacted findings for AWS keys, GitHub tokens, `sk-` API keys, Bearer tokens, `KEY=` exports, DB passwords, `user:pass@` URLs. `--scrub` deletes the lines (backup kept). |
| `dejsh flows` | Running the same 3 commands in a row | The repeated chain and a one-line alias for it. |
| `dejsh danger` | Having run something scary and got lucky | Close calls (`rm -rf ~`, `git push --force`, `curl \| sh`, `DROP TABLE`, `kubectl delete`) with a safer alternative for each. |
| `dejsh coach` | Small habits that waste time | `cd ../..` chains, `cat \| grep`, `ps \| grep`, repeated `clear`, long `cd` paths, each with the one-line fix. |
| `dejsh find <words>` | "What was that command?" | Matches, most recent first, with date and count. `--raw` prints only the top match. |
| `dejsh wrapped` | Wanting to share your terminal year | A card: totals, top tools, personality, hourly rhythm, longest streak. |
| `dejsh export` / `dejsh compare FILE` | "What tools does my teammate use that I don't?" | A profile of tool names and counts only (no arguments, no paths), and a two-way diff. |
| `dejsh dig` | Curiosity | Your history as geological layers, with named eras and fossils. |

#### `dejsh alias`

```console
$ dejsh alias -n 3

  alias gpom='git push origin main'
  120× typed · saves ~1920 keystrokes

  alias dcudb='docker compose up -d --build'
  40× typed · saves ~920 keystrokes

  alias cdmyawes='cd ~/projects/my-awesome-app'
  40× typed · saves ~800 keystrokes

  Add them:  dejsh alias --raw >> ~/.zshrc && source ~/.zshrc
```

#### `dejsh leaks`

```console
$ dejsh leaks

  line 623  Secret assignment  export AWS_SECRET_ACCESS_KEY=<wJa...40>
  line 624  GitHub token       git clone https://<ghp...40>@github.com/x/y.git
  line 626  Database password  mysql -u root -p<hun...13> mydb

  3 possible secret(s). Secrets are shown redacted; dejsh never prints them in full.
  Rotate these credentials — deleting history does not un-leak anything already synced or backed up.
```

Rotate anything it finds. `dejsh leaks --scrub` then removes those lines after you confirm and keeps a `.dejsh-backup` copy. Open a new shell afterwards, because a running shell may write its in-memory history back on exit.

#### `dejsh wrapped`

```console
  ╭──────────────────────────────────────────────────╮
  │  TERMINAL WRAPPED  2026
  │  4210 commands · 212 distinct tools
  │  you are: The Git Gardener (night shift)
  │
  │  git       ███████████████████████ 1203
  │  docker    ██████ 310
  │  npm       █████ 264
  │
  │  rhythm  00h ▃▂▁▁▁▁▁▂▄▆▇█▇▆▆▇▆▅▄▃▄▅▄▃ 23h
  │  peak hour: 11:00 · active 212 days · longest streak 41 days
  ╰──────────────────────────────────────────────────╯
```

#### `dejsh compare`

```console
$ dejsh export > me.tsv                 # share this: tool names and counts only
$ dejsh compare senior-dev.tsv

  THEY USE, YOU NEVER HAVE

  terraform plan         40× for them
  fzf                    22× for them
  rg                     18× for them

  YOU USE, THEY NEVER DO
  ...
```

## Install

**One-liner** (installs to `~/.local/bin`):

```sh
curl -fsSL https://raw.githubusercontent.com/victorabuchi/dejsh/main/install.sh | bash
```

**Homebrew:**

```sh
brew install victorabuchi/dejsh/dejsh
```

**From a clone:**

```sh
git clone https://github.com/victorabuchi/dejsh.git
cd dejsh && ./install.sh          # or: PREFIX_BIN=/usr/local/bin ./install.sh
```

**No install:** `./dejsh` runs in place.

If `~/.local/bin` isn't on your `PATH`, add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.zshrc` or `~/.bashrc`.

**Requirements:** bash 3.2+ (the macOS default works), plus `awk`, `sort`, `cksum` and `date` (BSD and GNU variants both work). A 256-colour UTF-8 terminal is recommended.

## Tab completion

dejsh completes its commands, flags and arguments in zsh, bash and fish.

```sh
dejsh completion zsh --install     # or: bash, fish. Then open a new terminal.
dejsh <TAB>                        # fix  fixes  resume  slow  script ...
dejsh leaks --<TAB>                # --scrub  --json  ...
```

`--install` adds one small block to your `~/.zshrc`, `~/.bashrc` or `~/.config/fish/config.fish` (and won't add it twice). To load it yourself instead: `eval "$(dejsh completion zsh)"` (bash: the same with `bash`; fish: `dejsh completion fish | source`). **Homebrew installs the completions for you.**

## Usage

```
dejsh [command] [options]

  -f FILE      history file (default: $HISTFILE, ~/.zsh_history, ~/.bash_history)
  -n N         rows to show (default 10)
  --raw        machine output: alias lines only, or the top match for `find`
  --scrub      with `leaks`: delete flagged lines (asks first, keeps a backup)
  --json       machine-readable output (every analysis command; not `script`, `wrapped`, `dig`, `hook`)
  --run        with `fix`: offer to apply the remembered fix (asks first)
  --since 30m  with `script`: only commands from the last 30m / 2h / 1d
  --all        with `resume`: every project
  -l N -w N    with `dig`: number of layers, width
```

Run `dejsh help` for the full command list.

## Timestamps (optional, improves dates and flows)

- **zsh:** `setopt EXTENDED_HISTORY` in `~/.zshrc`
- **bash:** `export HISTTIMEFORMAT="%F %T "` in `~/.bashrc`
- **fish:** nothing to do, fish records timestamps by default

Without timestamps everything still works. `flows` just can't filter by time gap, and `dig` and `wrapped` have less to show. The recorder makes this unnecessary for anything it records.

## How it works

1. **Load.** One pass normalises your history (zsh extended format, bash timestamp comments) into `time, command` rows. dejsh's own invocations are excluded.
2. **Analyse.** Each command is a small `awk` program over those rows. Command keys treat `git push` and `docker compose` as distinct tools, and skip `sudo`, `time` and `VAR=x` prefixes.
3. **Remember (optional).** The recorder is a few lines of `preexec`/`precmd` (zsh) or `DEBUG` trap/`PROMPT_COMMAND` (bash). It appends `epoch, exit code, duration, cwd, command` to a plain TSV file you can read, grep or delete.
4. **Render.** Output is plain text with ANSI colour. Every analysis also has a machine-friendly form (`--raw`, `export`).

## Privacy

- **Local only.** dejsh makes no network requests.
- **Writes are limited to:** the history file during `leaks --scrub` (with a backup), and `~/.dejsh/journal.tsv` if you install the recorder (mode 600).
- **The recorder skips** commands containing `token`, `secret`, `password`, `apikey`, `bearer`, `akia`, `private key`, and any command starting with a space.
- **Secrets are never printed in full.** `leaks` shows a redacted preview.
- **Sharing is opt-in and minimal.** `dejsh export` emits tool names and counts only, never arguments or paths.
- **Remove the recorder** by deleting the block between the `dejsh recorder` markers in your rc file, and `~/.dejsh/` if you want the data gone.

## FAQ

**Does the recorder slow down my shell?**
It adds one `printf` append per command. The zsh version forks nothing. The bash version makes one `date` call per prompt, because bash 3.2 has no built-in epoch clock.

**Why doesn't `dejsh fix` know my fix yet?**
It learns from failures you've already had since installing the recorder. It needs a command to fail and later succeed within 15 minutes, and the pattern to repeat at least twice.

**Will `leaks` catch everything?**
No. It is pattern-based and misses secrets with no recognisable shape. Treat it as a smoke detector, not an audit.

**Does it work with fish?**
Yes. dejsh reads `~/.local/share/fish/fish_history`, and `dejsh hook fish --install` adds the recorder to `~/.config/fish/config.fish`. The fish recorder and fish completions are tested in real fish shells on Linux and macOS in CI, the same as zsh and bash.

**Is it safe to run `dejsh alias --raw >> ~/.zshrc`?**
It skips names that already exist as commands or aliases and never emits commands that look like they contain secrets. Skim the output first if you like. It's plain alias lines.

## Limits

- A multi-line block pasted into the terminal is recorded as one entry (the shell runs it as a single command line), so it teaches dejsh nothing about the individual commands. Type commands one at a time.
- Plain history has no exit codes or directories. `fix`, `fixes`, `resume`, `slow` and success-only `script` only know about commands run after you install the recorder.
- Typo detection compares against tools you use often, and skips anything that exists on your `PATH`.
- `wrapped` computes hours using your current timezone offset, so it can be off by an hour across daylight-saving changes.

## Roadmap

- [ ] `fix --run` for multi-step fixes
- [ ] More secret patterns and a `leaks --watch` mode that warns as you type a secret into a command

Ideas and votes welcome in the issues. See the [CHANGELOG](CHANGELOG.md) for what has shipped.

## Contributing

Issues and pull requests are welcome. The whole tool is one script, and each command is a small, independent function, so it's easy to add one. See [CONTRIBUTING.md](CONTRIBUTING.md). Run `bash tests/run.sh` before opening a PR; CI runs it on Ubuntu and macOS.

## License

[MIT](LICENSE) © Victor Abuchi
