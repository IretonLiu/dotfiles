#!/usr/bin/env bash
set -euo pipefail

# Keep workspace 1 on the laptop panel while the lid is open, but move it to an
# external monitor before disabling the laptop panel when the lid is closed.
# Override these from the environment if this machine's output names change.
INTERNAL_MONITOR="${HYPR_INTERNAL_MONITOR:-eDP-1}"
INTERNAL_MODE="${HYPR_INTERNAL_MODE:-1920x1200@60}"
INTERNAL_POSITION="${HYPR_INTERNAL_POSITION:-auto-down}"
INTERNAL_SCALE="${HYPR_INTERNAL_SCALE:-1}"
PREFERRED_EXTERNAL="${HYPR_EXTERNAL_MONITOR:-}"
WORKSPACE_ID="${HYPR_LID_WORKSPACE_ID:-1}"
EXTERNAL_CLOSED_MODE="${HYPR_EXTERNAL_CLOSED_MODE:-preferred}"
EXTERNAL_CLOSED_POSITION="${HYPR_EXTERNAL_CLOSED_POSITION:-0x0}"
EXTERNAL_CLOSED_SCALE="${HYPR_EXTERNAL_CLOSED_SCALE:-1}"

active_monitors() {
    hyprctl monitors | awk '/^Monitor / { print $2 }'
}

first_active_external() {
    if [[ -n "$PREFERRED_EXTERNAL" ]] && active_monitors | grep -Fxq "$PREFERRED_EXTERNAL"; then
        printf '%s\n' "$PREFERRED_EXTERNAL"
        return 0
    fi

    active_monitors | awk -v internal="$INTERNAL_MONITOR" '$0 != internal { print; exit }'
}

lid_state() {
    local state_file
    state_file=$(find /proc/acpi/button/lid -name state -print -quit 2>/dev/null || true)
    if [[ -n "$state_file" ]] && grep -qi closed "$state_file"; then
        printf 'closed\n'
    else
        printf 'open\n'
    fi
}

move_workspace_to_monitor() {
    local monitor="$1"

    hyprctl keyword workspace "$WORKSPACE_ID,monitor:$monitor,default:true" >/dev/null || true
    hyprctl dispatch moveworkspacetomonitor "$WORKSPACE_ID $monitor" >/dev/null || true
    hyprctl dispatch focusmonitor "$monitor" >/dev/null || true
    hyprctl dispatch workspace "$WORKSPACE_ID" >/dev/null || true
}

close_lid() {
    local external
    external=$(first_active_external)

    # Do not disable the laptop panel if there is nowhere else to put workspace 1.
    [[ -n "$external" ]] || exit 0

    # When the laptop panel is removed, force the external display to become the
    # origin display. If it keeps an auto-up/auto-down offset, layer surfaces
    # like quickshell and hyprpaper can appear shifted to the side/off-screen.
    hyprctl keyword monitor "$external,$EXTERNAL_CLOSED_MODE,$EXTERNAL_CLOSED_POSITION,$EXTERNAL_CLOSED_SCALE,bitdepth,12" >/dev/null
    sleep 0.1
    move_workspace_to_monitor "$external"
    hyprctl keyword monitor "$INTERNAL_MONITOR,disable" >/dev/null
    sleep 0.2
    hyprctl keyword monitor "$external,$EXTERNAL_CLOSED_MODE,$EXTERNAL_CLOSED_POSITION,$EXTERNAL_CLOSED_SCALE,bitdepth,12" >/dev/null
    move_workspace_to_monitor "$external"
}

open_lid() {
    hyprctl keyword monitor "$INTERNAL_MONITOR,$INTERNAL_MODE,$INTERNAL_POSITION,$INTERNAL_SCALE,bitdepth,12" >/dev/null
    sleep 0.2
    move_workspace_to_monitor "$INTERNAL_MONITOR"
}

case "${1:-auto}" in
    closed|close|on)
        close_lid
        ;;
    open|off)
        open_lid
        ;;
    auto)
        case "$(lid_state)" in
            closed) close_lid ;;
            *) open_lid ;;
        esac
        ;;
    *)
        echo "Usage: $0 [auto|closed|open]" >&2
        exit 2
        ;;
esac
