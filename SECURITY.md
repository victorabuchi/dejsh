# Security policy

dejsh reads your shell history and, if you opt in, records commands to a local file. Because that data can be sensitive, security reports are taken seriously.

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Use GitHub's private reporting instead:
**Security tab → "Report a vulnerability"** on this repository.

Include what you did, what you expected, and what happened. You can expect a first reply within a few days.

## What is in scope

- Anything that makes dejsh print a secret in full, or write one somewhere unexpected.
- The recorder writing commands it should have skipped (those containing `token`, `secret`, `password`, `apikey`, `bearer`, `akia`, `private key`, or starting with a space).
- Unsafe handling of the history file by `leaks --scrub`, or of the journal's permissions.
- Anything that causes dejsh to run a command without asking (`fix --run` must always confirm first).

## Design promises

- No network access, ever.
- The recorder's journal (`~/.dejsh/journal.tsv`) is created with mode 600 in a mode 700 directory.
- `leaks` output is always redacted.
- `export` shares tool names and counts only, never arguments or paths.
