#!/usr/bin/env bash
# Installs dejsh into ~/.local/bin (override with PREFIX_BIN=/some/dir)
set -e
DEST=${PREFIX_BIN:-$HOME/.local/bin}
URL=https://raw.githubusercontent.com/victorabuchi/dejsh/main/dejsh
mkdir -p "$DEST"
if [ -f "$(dirname "$0")/dejsh" ]; then cp "$(dirname "$0")/dejsh" "$DEST/dejsh"; else curl -fsSL "$URL" -o "$DEST/dejsh"; fi
chmod +x "$DEST/dejsh"
echo "Installed to $DEST/dejsh"
case ":$PATH:" in *":$DEST:"*) ;; *) echo "Add this to your shell profile: export PATH=\"$DEST:\$PATH\"";; esac
