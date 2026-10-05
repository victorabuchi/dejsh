#!/usr/bin/env bash
# Installs hindsh into ~/.local/bin (override with PREFIX_BIN=/some/dir)
set -e
DEST=${PREFIX_BIN:-$HOME/.local/bin}
URL=https://raw.githubusercontent.com/victorabuchi/hindsh/main/hindsh
mkdir -p "$DEST"
if [ -f "$(dirname "$0")/hindsh" ]; then cp "$(dirname "$0")/hindsh" "$DEST/hindsh"; else curl -fsSL "$URL" -o "$DEST/hindsh"; fi
chmod +x "$DEST/hindsh"
echo "Installed to $DEST/hindsh"
case ":$PATH:" in *":$DEST:"*) ;; *) echo "Add this to your shell profile: export PATH=\"$DEST:\$PATH\"";; esac
