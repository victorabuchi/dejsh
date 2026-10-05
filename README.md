# strata

**Excavate your shell history like an archaeologist.**

`strata` reads your command history and renders it as a geological cross-section of your terminal life: oldest commands at the bedrock, today at the surface. Each layer is named after the era you lived through, and the rare commands you used heavily once and never again show up as fossils embedded in the rock.

One bash script. No dependencies beyond `awk`, `sort`, `cksum` and `date`, which ship with macOS and Linux.

```
  STRATA — 1200 commands, 5 layers, source: ~/.zsh_history

  ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀  ← surface (today)
  ████████████████████████████████████████████████████████████████  The Wandering
  ████████████████████████████████████████████████████████████████  Dec 2029 → Jun 2031 · 240 cmds
  ████████████████████████████████████████████████████████████████  ls 35%, grep, cd
  ▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚  The Brewing Age
  ▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚  Jun 2028 → Dec 2029 · 240 cmds
  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ☠ kubectl ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  The Editor Wars
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  The Container Era
  ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  ← bedrock (your first command)

  FIELD NOTES
   ☠ fossil   layer 2: kubectl (40 uses, never seen in any other layer)
   🌱 invasive species in the newest layer: 3 new commands
   🦖 extinct (abandoned: never used again after their layer): 11 commands
```

(The real output is in colour: each layer gets its own mineral hue.)

## What you get

| Feature | Meaning |
|---|---|
| **Layers** | Your history split into equal slices by command count. Thicker rock = more activity. |
| **Eras** | Each layer is named for its dominant command: `git` → *The Version Age*, `docker` → *The Container Era*, `npm` → *The Node Dynasty*, `vim` → *The Editor Wars*, and so on. Unknown commands get *The &lt;name&gt; Epoch*. |
| **Fossils** | A command heavily used in exactly one layer and never anywhere else, embedded as `☠ name`. |
| **Invasive species** | Commands that first appeared in your newest layer. |
| **Extinct** | Commands you abandoned, never seen again after their layer. |
| **Dates** | Layer date ranges, when your history records timestamps (see below). |

## Install

**One-liner** (installs to `~/.local/bin`):

```sh
curl -fsSL https://raw.githubusercontent.com/victorabuchi/strata/main/install.sh | bash
```

**From a clone:**

```sh
git clone https://github.com/victorabuchi/strata.git
cd strata
./install.sh            # or: PREFIX_BIN=/usr/local/bin ./install.sh
```

**Or just run it in place:**

```sh
./strata
```

If the installer says `~/.local/bin` is not on your `PATH`, add this to `~/.zshrc` or `~/.bashrc`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```sh
strata                       # auto-detects $HISTFILE, ~/.zsh_history, or ~/.bash_history
strata -l 12                 # 12 layers (default 8)
strata -w 90                 # 90 columns wide (default 64)
strata ~/some/other_history  # excavate any history file
```

| Flag | Default | Description |
|---|---|---|
| `-l N` | `8` | Number of layers |
| `-w N` | `64` | Width of the cross-section in columns |
| `FILE` | auto | History file to read |

## Getting dates on your layers

Date ranges need timestamps in your history. Without them, strata still works and layers by order, but dates show as `?`.

- **zsh:** add `setopt EXTENDED_HISTORY` to `~/.zshrc`.
- **bash:** add `export HISTTIMEFORMAT="%F %T "` to `~/.bashrc`. (Note: bash timestamps are stored as `#epoch` comment lines, which strata currently ignores, so bash history is layered by order.)

Timestamps only apply to commands you run after enabling the setting.

## How it works

1. **Normalise.** Each history line is reduced to the command that actually ran, skipping `VAR=x` prefixes and wrappers like `sudo`, `time` and `nohup`, and stripping paths (`/usr/bin/git` → `git`). zsh extended-history timestamps are parsed.
2. **Dig.** A single `awk` pass slices history into N layers and records, per layer, the top three commands, the earliest and latest timestamps, the fossil, and which commands appeared or vanished.
3. **Render.** Bash draws each layer with a texture and 256-colour hue derived from a checksum of its top command, so the same command always gets the same rock.

## Requirements

- bash 3.2+ (the macOS default works)
- `awk`, `sort`, `cksum`, `cut`, `date` (macOS and GNU variants both supported)
- A terminal with 256-colour support and a UTF-8 locale

## Privacy

strata runs entirely locally. It reads your history file and prints to your terminal. It makes no network requests and writes nothing.

## Contributing

Ideas welcome: more era names, bash `#epoch` timestamp support, filtering heredoc noise, `--json` output. Open an issue or a pull request.

## License

[MIT](LICENSE)
