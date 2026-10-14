#!/usr/bin/env bash
# Start notifications with the last selected shared theme. The theme command
# creates a dark fallback on a fresh install.
exec "$HOME/dotfiles/scripts/theme" dunst
