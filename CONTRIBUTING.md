# Contributing

Thanks for helping. dejsh is a single bash script (`dejsh`); each command is a small function, so adding one is straightforward.

## Setup

```sh
git clone https://github.com/victorabuchi/dejsh.git
cd dejsh
bash tests/run.sh      # should end with: N passed, 0 failed
```

## Ground rules

- **Target macOS's default bash 3.2** (`/bin/bash`). No associative arrays, no `${var^^}`, no `mapfile`. CI runs the suite on Ubuntu and macOS, and you should run `/bin/bash tests/run.sh` on a Mac.
- **No dependencies** beyond standard `awk`, `sed`, `sort`, `cut`, `date`. It must work with BSD and GNU variants.
- **No network access.** Ever.
- **Never print a secret in full.** Anything that touches credentials redacts.
- **Never run anything without asking** (see `fix --run`).
- Fake credentials in tests are assembled at runtime (`"gh""p_..."`) so GitHub secret scanning doesn't block pushes. Follow that pattern.

## Adding a command

1. Write `_yourcmd_data()` (machine rows) and `cmd_yourcmd()` (pretty output).
2. Add the name to the `case $CMD in` list near the top, to `usage()`, and to the dispatch at the bottom.
3. Add tests to `tests/run.sh` and a row to the README.
4. Add a line to `CHANGELOG.md`.

## Pull requests

Keep them focused. Say what problem the change solves. CI must pass.
