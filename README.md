# strata

**Your shell history knows what's wrong with your workflow. strata tells you, and fixes it.**

You've typed `git push origin main` hundreds of times. You've typo'd `git` as `gti` every week for a year. Somewhere in your history there may be an API key you pasted once and forgot. strata reads the history file you already have, finds these problems, and hands you the fix.

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
- History has no exit codes or working directories, so strata can't know which commands failed or where they ran.
- `leaks` is pattern-based. It will miss secrets with no recognisable shape and may flag harmless values. Treat it as a smoke detector, not an audit.
- Typo detection compares command names to your frequently used ones; it skips anything that exists on your `PATH`.

## Privacy

Everything runs locally. strata reads your history file and prints to your terminal. It makes no network requests, and the only thing it ever writes is the history file during `leaks --scrub` (plus the backup next to it).

## Requirements

bash 3.2+ (macOS default is fine), plus `awk`, `sort`, `cksum`, `date` (BSD and GNU variants both work). A 256-colour UTF-8 terminal for `dig`.

## Contributing

Ideas: more secret patterns, more era names, `--json` output, fish shell support. Issues and PRs welcome.

## License

[MIT](LICENSE)
