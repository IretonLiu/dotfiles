#!/bin/bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-launcher"
mkdir -p "$STATE_DIR"
printf 'false' > "$STATE_DIR/visible"

exec qs -p "$HOME/dotfiles/quickshell/launcher"
