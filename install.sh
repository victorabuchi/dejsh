#!/usr/bin/env bash
# Installs strata into ~/.local/bin (override with PREFIX_BIN=/some/dir)
set -e
DEST=${PREFIX_BIN:-$HOME/.local/bin}
URL=https://raw.githubusercontent.com/victorabuchi/strata/main/strata
mkdir -p "$DEST"
if [ -f "$(dirname "$0")/strata" ]; then cp "$(dirname "$0")/strata" "$DEST/strata"; else curl -fsSL "$URL" -o "$DEST/strata"; fi
chmod +x "$DEST/strata"
echo "Installed to $DEST/strata"
case ":$PATH:" in *":$DEST:"*) ;; *) echo "Add this to your shell profile: export PATH=\"$DEST:\$PATH\"";; esac
