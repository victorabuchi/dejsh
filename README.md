# strata

**Your shell has a memory problem. strata gives it a memory, then uses it to fix things.**

You've typed `git push origin main` hundreds of times. You've typo'd `git` as `gti` every week for a year. Somewhere in your history there may be an API key you pasted once and forgot. strata reads the history file you already have, finds these problems, and hands you the fix.

Plain history can't tell you where a command ran, how long it took, or whether it failed. strata can record that locally (opt-in), and builds on it: it learns how *you* fix errors, shows where you left off in a project, and writes scripts from what you just did.

One bash script. No dependencies, no network, nothing written unless you ask. Works with zsh and bash on macOS and Linux.

```console
$ strata

  STRATA CHECKUP — 4,210 commands in ~/.zsh_history

  ✂  ALIASES  47 repeated commands could be aliases (~7,224 keystrokes)   → strata alias
  ✎  TYPOS    1 recurring typos                                           → strata typos
  🔑 SECRETS  4 possible secret(s) in plaintext!                          → strata leaks
  ⛓  FLOWS    13 workflows you repeat could be one command                → strata flows
  🔍 RECALL   find any past command by keywords                           → strata find <words>
  🪨 DIG      your history as rock layers                                 → strata dig
```

## The problems it solves

| You have this problem | Run | What you get |
|---|---|---|
| You retype the same long commands all day | `strata alias` | Ready-to-paste aliases, ranked by keystrokes saved. Skips names that clash with real commands or your existing aliases. |
| You keep mistyping `git`, `docker`, `kubectl` | `strata typos` | A fix-alias for each recurring typo (`gti` → `git`). |
| You pasted a token or password into a command once | `strata leaks` | Finds AWS keys, GitHub tokens, `sk-` API keys, Bearer tokens, `KEY=…` exports, DB passwords, `user:pass@` URLs. Shown redacted. `--scrub` deletes the lines (backup kept). |
| You run the same 3 commands in a row every time | `strata flows` | The repeated chain and a one-line alias that runs it. |
| "What was that docker command I ran last week?" | `strata find docker prune` | Matching commands, most recent first, with date and count. |
| You're curious about your terminal life | `strata dig` | Your history as geological layers, with named eras and fossils. |

### `strata alias`

```console
$ strata alias -n 3

  alias gpom='git push origin main'
  120× typed · saves ~1920 keystrokes

  alias dcudb='docker compose up -d --build'
  40× typed · saves ~920 keystrokes

  alias cdmyawes='cd ~/projects/my-awesome-app'
  40× typed · saves ~800 keystrokes

  Add them:  strata alias --raw >> ~/.zshrc && source ~/.zshrc
```

Commands containing anything that looks like a secret are never suggested, so strata won't copy a token into your `.zshrc`.

### `strata leaks`

```console
$ strata leaks

  line 623  Secret assignment  export AWS_SECRET_ACCESS_KEY=<wJa...40>
  line 624  GitHub token       git clone https://<ghp...40>@github.com/x/y.git
  line 626  Database password  mysql -u root -p<hun...13> mydb

  3 possible secret(s). Secrets are shown redacted; strata never prints them in full.
  Rotate these credentials — deleting history does not un-leak anything already synced or backed up.
```

Rotate any credential it finds. `strata leaks --scrub` then removes those lines from the history file after you confirm, and keeps a `.strata-backup` copy. Open a new shell afterwards, because a running shell may write its in-memory history back on exit.

### `strata flows`

```console
$ strata flows -n 2

  120×  git add → git commit → git push
      alias flow1='git add -A && git commit && git push origin main'

  40×  git status → git log → git diff
      alias flow2='git status && git log && git diff'
```

Only chains that ran within 15 minutes of each other count (when your history has timestamps). Rename the alias and edit the arguments to taste.

### `strata find`

```console
$ strata find kube prod

  Nov 18   14×  kubectl get pods -n production
```

All words must match, in any order. `strata find --raw docker prune` prints just the most recent match, so you can use it in scripts.

### `strata dig`

```
  ▓▓▓▓▓▓▓▓ ☠ export ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  The Version Age
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Oct 2025 → Nov 2025 · 156 cmds
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  git 74%, cd, docker
```

Your history sliced into layers (oldest at the bedrock), each named for its dominant command (`git` → *The Version Age*, `docker` → *The Container Era*), with commands used heavily in one layer only embedded as `☠` fossils. `-l 12` sets the layer count and `-w 90` the width.

## The memory layer (opt-in recorder)

```sh
strata hook --install      # adds a small hook to ~/.zshrc or ~/.bashrc, then open a new terminal
```

The hook appends one line per command (time, exit code, duration, directory, command) to `~/.strata/journal.tsv`, mode 600, local only. Commands containing `token`, `secret`, `password`, `key` words, or starting with a space are never recorded. With it on:

| You have this problem | Run | What you get |
|---|---|---|
| A command just failed and you know you've fixed this before | `strata fix` | The last failure, and what you ran last time it failed that way ("`npm start` failed → you ran `npm install`, worked 5 of 5 times"). |
| You can't remember how you usually fix things | `strata fixes` | Your personal troubleshooting memory: each recurring failure and the fix that worked. It also spots flaky commands (fixed by just re-running). |
| You come back to a project after a few days | `strata resume` | Your last session there: the commands, the step you stopped on (and if it failed), the git branch and uncommitted changes. `--all` lists every project by recency. |
| "What did I just do that worked? I need to repeat it." | `strata script -n 8` | The last 8 *successful* commands as a runnable `set -euo pipefail` script, starting in the right directory. Secret-looking lines are skipped. `--since 30m` limits it by time. |
| Your builds feel slow but you don't know why | `strata slow` | Time sinks ranked by total time, with average and worst case. |

```console
$ strata fix

  last failure (2 min ago, in ~/projects/shopify)
    ✗ npm start  (exit code 1)

  Last time `npm start` failed, you ran:
    npm install   (worked 5 of 5 times)
```

```console
$ strata resume

  WHERE YOU LEFT OFF in ~/projects/strata
  last session 2 h ago · 6 commands over 43s

   ✓ git status
   ✓ shellcheck strata
   ✓ git commit -m docs
   ✗ git push origin main (exit 1)

  ⚠ you stopped on a failing command: git push origin main
  git: on main, 1 uncommitted change(s)
```

## Works from history alone

| You have this problem | Run | What you get |
|---|---|---|
| You've run something scary and got lucky | `strata danger` | Close calls (`rm -rf ~`, `git push --force`, `curl \| sh`, `DROP TABLE`, `kubectl delete`...) with the safer alternative for each. |
| Small habits quietly waste your day | `strata coach` | `cd ../..` chains, `cat \| grep`, `ps \| grep`, repeated `clear`, long `cd` paths... each with the one-line fix. |
| You want to share your terminal year | `strata wrapped` | A shareable card: commands, top tools, your personality ("The Git Gardener"), your hourly rhythm, longest streak. |
| A new teammate asks "what tools do you use?" | `strata export > me.tsv` then `strata compare theirs.tsv` | A privacy-safe profile (tool names and counts only, no arguments or paths), and a diff: what they use that you've never touched, and the reverse. |

## Install

**One-liner** (installs to `~/.local/bin`):

```sh
curl -fsSL https://raw.githubusercontent.com/victorabuchi/strata/main/install.sh | bash
```

**From a clone:**

```sh
git clone https://github.com/victorabuchi/strata.git
cd strata && ./install.sh        # or: PREFIX_BIN=/usr/local/bin ./install.sh
```

If `~/.local/bin` isn't on your `PATH`, add `export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc` or `~/.bashrc`.

## Options

```
strata [command] [options]

  -f FILE     history file (default: $HISTFILE, ~/.zsh_history, ~/.bash_history)
  -n N        rows to show (default 10)
  --raw       machine output: alias lines only, or the top match for find
  --scrub     with `leaks`: delete flagged lines (asks first, keeps a backup)
  -l N -w N   dig: number of layers, width
```

## Get timestamps (optional, makes `flows` and dates better)

- **zsh:** `setopt EXTENDED_HISTORY` in `~/.zshrc`
- **bash:** `export HISTTIMEFORMAT="%F %T "` in `~/.bashrc`

Without timestamps everything still works; flows just can't filter by time gap, and `dig` shows `?` for dates. They only apply to commands you run after enabling them.

## Honest limits

- strata sees what your history file recorded. Shells that don't save history, or a very short history, give thin results.
- Plain history has no exit codes or working directories. `fix`, `fixes`, `resume`, `slow` and success-only `script` need the recorder, and only know about commands run after you install it.
- `leaks` is pattern-based. It will miss secrets with no recognisable shape and may flag harmless values. Treat it as a smoke detector, not an audit.
- Typo detection compares command names to your frequently used ones; it skips anything that exists on your `PATH`.

## Privacy

Everything runs locally. strata reads your history and prints to your terminal. It makes no network requests. It only writes: the history file during `leaks --scrub` (plus a backup), and `~/.strata/journal.tsv` if you install the recorder. `strata export` shares tool names and counts only, never arguments.

## Requirements

bash 3.2+ (macOS default is fine), plus `awk`, `sort`, `cksum`, `date` (BSD and GNU variants both work). A 256-colour UTF-8 terminal for `dig`.

## Contributing

Ideas: more secret patterns, more era names, `--json` output, fish shell support. Issues and PRs welcome.

## License

[MIT](LICENSE)
