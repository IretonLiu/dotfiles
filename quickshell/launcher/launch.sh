#!/bin/bash
set -euo pipefail

LAUNCHER_DIR="$HOME/dotfiles/quickshell/launcher"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-launcher"
VISIBILITY_FILE="$STATE_DIR/visible"

mkdir -p "$STATE_DIR"

if pgrep -u "$USER" -f "qs .*${LAUNCHER_DIR}|qs -p ${LAUNCHER_DIR}" >/dev/null 2>&1; then
    if [ -f "$VISIBILITY_FILE" ] && [ "$(cat "$VISIBILITY_FILE" 2>/dev/null)" = "true" ]; then
        printf 'false' > "$VISIBILITY_FILE"
    else
        printf 'true' > "$VISIBILITY_FILE"
    fi
else
    printf 'true' > "$VISIBILITY_FILE"
    qs -p "$LAUNCHER_DIR" >/dev/null 2>&1 &
fi
