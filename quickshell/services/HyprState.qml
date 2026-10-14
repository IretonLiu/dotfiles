pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    readonly property string configFile: Quickshell.env("HYPR_CONFIG_FILE") || (Quickshell.env("HOME") + "/.config/hypr/hyprland.conf")

    // Shared by every topbar instance so one Hyprland event produces one IPC
    // refresh, rather than one refresh per connected display.
    property int refreshToken: 0
    property var workspaceAssignments: ({})

    function assignmentsFor(monitorName) {
        return workspaceAssignments[monitorName] || [];
    }

    function refreshForEvent(name) {
        const eventName = name.endsWith("v2") ? name.slice(0, -2) : name;

        if (["workspace", "moveworkspace", "focusedmon", "createworkspace", "destroyworkspace", "renameworkspace", "activespecial"].includes(eventName)) {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
        } else if (["openwindow", "closewindow", "movewindow"].includes(eventName)) {
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
        } else if (eventName.includes("mon")) {
            Hyprland.refreshMonitors();
        } else if (eventName.includes("workspace")) {
            Hyprland.refreshWorkspaces();
        } else if (eventName.includes("window") || eventName.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(eventName)) {
            Hyprland.refreshToplevels();
        } else {
            return;
        }

        refreshToken++;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.refreshForEvent(event.name);
        }
    }

    FileView {
        path: root.configFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const assignments = ({});
            const lines = (text() || "").split("\n");

            for (const line of lines) {
                const match = line.match(/^\s*workspace\s*=\s*(\d+)\s*,\s*monitor:([^,\s]+)/);
                if (!match)
                    continue;

                const workspaceId = Number(match[1]);
                const monitorName = match[2];
                if (!assignments[monitorName])
                    assignments[monitorName] = [];
                if (!assignments[monitorName].includes(workspaceId))
                    assignments[monitorName].push(workspaceId);
            }

            root.workspaceAssignments = assignments;
            root.refreshToken++;
        }
    }
}
