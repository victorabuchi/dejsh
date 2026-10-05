# Changelog

All notable changes. Format based on [Keep a Changelog](https://keepachangelog.com/).

## [0.9.0]
- `fix --run` now handles multi-step fixes: shows the numbered steps, asks once, runs them in order and stops at the first failure.
- `fix --run` refuses to auto-apply a fix that contains a risky command (`rm -rf`, `sudo`, `--force`, `reset --hard`, `DROP`, `dd`, `mkfs`, `chmod -R`).
- New `dejsh guard [zsh|bash|fish] [--install]`: commands containing a secret still run but are never written to your history file. Tested against real shell histories in CI, with a no-guard control that proves the secret *would* otherwise be saved.
- Completions know about `guard`.

## [0.8.0]
- Tab completion for zsh, bash and fish: `dejsh completion <shell> [--install]`. Completes commands, flags, and arguments (shells, time windows, files).
- Homebrew installs the completions automatically.
- CI now installs fish and drives each shell through a real pseudo-terminal, so the zsh, bash and fish recorders and the fish completions are all tested for real (114 checks).
- The zsh completion file works both when `eval`'d and when autoloaded from `fpath` (how Homebrew installs it).

## [0.7.1]
- `fix` / `fixes` now measure the fix from the *last* failure before success, so noisy retries and abandoned attempts no longer pollute the remembered fix.

## [0.7.0]
- `alias` now suggests stem aliases for commands whose last argument varies (`git commit -m` instead of one frozen message).
- `flows` no longer freezes one particular argument (like a commit message) into a suggested macro.
- `--json` added to `danger`, `coach`, `slow` and `resume`.
- Tests grew to 87 checks, passing on Ubuntu and macOS (including macOS bash 3.2).
- Added CHANGELOG, SECURITY, CONTRIBUTING, issue and PR templates.

## [0.6.0]
- Renamed the project to **dejsh** (déjà vu + sh). Config dir is `~/.dejsh`; env vars are `DEJSH_HIST` and `DEJSH_JOURNAL`.
- Added an automated test suite (`tests/run.sh`, 74 checks) and CI on Ubuntu and macOS.

## [0.4.0]
- fish shell support (history parsing and recorder).
- `fix --run` offers to re-apply a remembered fix (always asks first).
- `--json` output for alias, typos, flows, leaks, fixes, find, export and the checkup.
- Ten more secret patterns: Stripe, Google, SendGrid, npm, PyPI, Hugging Face, DigitalOcean, GitLab, JWT, AWS temporary keys.
- Homebrew tap.

## [0.3.0]
- Opt-in recorder (zsh, bash) that adds exit code, duration and directory to each command.
- New commands built on it: `fix`, `fixes`, `resume`, `slow`, `script`.
- New history-only commands: `danger`, `coach`, `wrapped`, `export`, `compare`.

## [0.2.0]
- Turned the original history visualiser into an audit tool: `alias`, `typos`, `leaks`, `flows`, `find`.

## [0.1.0]
- First version: history rendered as geological layers (`dig`).
