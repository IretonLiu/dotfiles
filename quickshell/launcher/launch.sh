#!/bin/bash
# Quickshell Launcher Singleton Wrapper
# Uses Quickshell's native instance listing for reliable detection

LAUNCHER_PATH="/home/ireton/dotfiles/quickshell/launcher/shell.qml"

# Extract instance ID if already running
INST_ID=$(qs list --all | grep -B 3 "$LAUNCHER_PATH" | grep "Instance" | awk '{print $2}' | sed 's/://')

if [ -n "$INST_ID" ]; then
    # Already running: kill it to toggle off
    qs kill "$INST_ID"
else
    # Not running: launch it
    qs -p "/home/ireton/dotfiles/quickshell/launcher"
fi
