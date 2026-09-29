#!/usr/bin/env bash
set -euo pipefail

# Lid-aware workspace placement for Hyprland.
#
# Baseline monitor layout comes from the monitor= rules in hyprland.conf. This
# avoids inventing a separate closed-lid layout, which gets buggy with multiple
# external monitors. On lid close we reapply the configured external monitor
# rules, move workspace 1 to the second external display when available, then
# disable eDP-1. On lid open we reapply the configured monitor rules and move
# workspace 1 back to eDP-1.

CONFIG_FILE="${HYPR_CONFIG_FILE:-${HOME}/.config/hypr/hyprland.conf}"
INTERNAL_MONITOR="${HYPR_INTERNAL_MONITOR:-eDP-1}"
PREFERRED_EXTERNAL="${HYPR_EXTERNAL_MONITOR:-}"
WORKSPACE_ID="${HYPR_LID_WORKSPACE_ID:-1}"

monitor_names() {
    hyprctl monitors | awk '/^Monitor / { print $2 }'
}

monitor_is_active() {
    local monitor="$1"
    monitor_names | grep -Fxq "$monitor"
}

configured_monitor_rule() {
    local monitor="$1"

    awk -F= -v monitor="$monitor" '
        /^[[:space:]]*monitor[[:space:]]*=/ {
            rule=$2
            sub(/^[[:space:]]*/, "", rule)
            split(rule, parts, ",")
            name=parts[1]
            sub(/^[[:space:]]*/, "", name)
            sub(/[[:space:]]*$/, "", name)
            if (name == monitor) {
                print rule
                exit
            }
        }
    ' "$CONFIG_FILE"
}

configured_external_monitors() {
    awk -F= -v internal="$INTERNAL_MONITOR" '
        /^[[:space:]]*monitor[[:space:]]*=/ {
            rule=$2
            sub(/^[[:space:]]*/, "", rule)
            split(rule, parts, ",")
            name=parts[1]
            sub(/^[[:space:]]*/, "", name)
            sub(/[[:space:]]*$/, "", name)
            if (name != "" && name != internal)
                print name
        }
    ' "$CONFIG_FILE"
}

external_target_monitor() {
    if [[ -n "$PREFERRED_EXTERNAL" ]] && monitor_is_active "$PREFERRED_EXTERNAL"; then
        printf '%s\n' "$PREFERRED_EXTERNAL"
        return 0
    fi

    mapfile -t externals < <(configured_external_monitors)

    # Prefer the second configured external monitor when it is active. In the
    # current layout that is DP-3, so closing the lid moves workspace 1 there
    # instead of to HDMI-A-1.
    if ((${#externals[@]} >= 2)) && monitor_is_active "${externals[1]}"; then
        printf '%s\n' "${externals[1]}"
        return 0
    fi

    # Fallback to the first configured external monitor that is active.
    for monitor in "${externals[@]}"; do
        if monitor_is_active "$monitor"; then
            printf '%s\n' "$monitor"
            return 0
        fi
    done

    # Final fallback to any active non-internal output.
    monitor_names | awk -v internal="$INTERNAL_MONITOR" '$0 != internal { print; exit }'
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

apply_monitor_rule() {
    local monitor="$1"
    local rule

    rule=$(configured_monitor_rule "$monitor")
    [[ -n "$rule" ]] || return 0

    hyprctl keyword monitor "$rule" >/dev/null || true
}

apply_external_rules() {
    while IFS= read -r monitor; do
        apply_monitor_rule "$monitor"
    done < <(configured_external_monitors)
}

apply_all_configured_rules() {
    awk -F= '
        /^[[:space:]]*monitor[[:space:]]*=/ {
            rule=$2
            sub(/^[[:space:]]*/, "", rule)
            print rule
        }
    ' "$CONFIG_FILE" | while IFS= read -r rule; do
        [[ -n "$rule" ]] && hyprctl keyword monitor "$rule" >/dev/null || true
    done
}

move_workspace_to_monitor() {
    local monitor="$1"

    hyprctl keyword workspace "$WORKSPACE_ID,monitor:$monitor,default:true" >/dev/null || true
    hyprctl dispatch moveworkspacetomonitor "$WORKSPACE_ID $monitor" >/dev/null || true
    hyprctl dispatch focusmonitor "$monitor" >/dev/null || true
    hyprctl dispatch workspace "$WORKSPACE_ID" >/dev/null || true
}

close_lid() {
    local target
    target=$(external_target_monitor)

    # Do not disable the laptop panel if there is nowhere else to put workspace 1.
    [[ -n "$target" ]] || exit 0

    apply_external_rules
    sleep 0.1
    move_workspace_to_monitor "$target"
    hyprctl keyword monitor "$INTERNAL_MONITOR,disable" >/dev/null
    sleep 0.2
    apply_external_rules
    move_workspace_to_monitor "$target"
}

open_lid() {
    apply_all_configured_rules
    sleep 0.2
    if monitor_is_active "$INTERNAL_MONITOR"; then
        move_workspace_to_monitor "$INTERNAL_MONITOR"
    fi
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
