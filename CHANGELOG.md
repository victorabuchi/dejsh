# Changelog

All notable changes. Format based on [Keep a Changelog](https://keepachangelog.com/).

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
