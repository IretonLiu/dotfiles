#!/usr/bin/env bash
# Backward-compatible entry point for the shared theme synchronizer.
exec "$(dirname "$0")/theme" "$@"
