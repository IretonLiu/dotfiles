import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.leftMargin: 10
    Layout.rightMargin: 10

    required property ShellScreen screen

    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted
    property color bgColor: Services.Theme.surface

    // Default workspace ownership per monitor/topbar. Keep this in sync with
    // ~/.config/hypr/hyprland.conf workspace rules.
    readonly property var workspaceAssignments: ({
        "eDP-1": [1],
        "HDMI-A-1": [2],
        "DP-3": [3]
    })

    // Bumped from Hyprland IPC events. Some nested Hyprland properties (for
    // example monitor.activeWorkspace and workspace.lastIpcObject.monitor) do
    // not always notify QML bindings on their own, so make the workspace model
    // explicitly recompute after workspace/window/monitor changes.
    property int refreshToken: 0

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property string monitorName: monitor?.name ?? screen.name
    readonly property bool isInternalMonitor: monitorName.startsWith("eDP")
    readonly property int activeWorkspaceId: {
        refreshToken;
        if (Hyprland.focusedMonitor?.name === monitorName)
            return Hyprland.focusedWorkspace?.id ?? 0;

        return monitor?.activeWorkspace?.id ?? monitor?.lastIpcObject?.activeWorkspace?.id ?? 0;
    }
    readonly property var activeExternalMonitors: {
        refreshToken;
        return Hyprland.monitors.values.filter(m => !m.name.startsWith("eDP")).map(m => m.name);
    }
    readonly property var assignedWorkspaceIds: {
        if (isInternalMonitor)
            return [1];

        // If only one external display is connected, show both external
        // workspaces there. If multiple external displays are connected, split
        // them by the explicit monitor map below.
        if (activeExternalMonitors.length <= 1 && activeExternalMonitors.indexOf(monitorName) !== -1)
            return [2, 3];

        const assigned = workspaceAssignments[monitorName];
        if (assigned)
            return assigned;

        return [2, 3];
    }

    function workspaceMonitorName(ws) {
        const monitor = ws?.monitor ?? ws?.lastIpcObject?.monitor ?? ws?.lastIpcObject?.monitorName ?? "";
        return typeof monitor === "string" ? monitor : (monitor?.name ?? "");
    }

    function workspaceBelongsHere(ws) {
        if (!ws || ws.id <= 0 || ws.name.startsWith("special:"))
            return false;

        return workspaceMonitorName(ws) === monitorName || assignedWorkspaceIds.indexOf(ws.id) !== -1;
    }

    // Hyprland.workspaces can miss/lag the window count in some cases, and the
    // old fixed `model: 10` silently dropped occupied workspaces above 10.
    // Build the shown ids from default assignments, per-monitor workspace IPC
    // data, and live toplevels.
    readonly property var occupiedWorkspaces: {
        refreshToken;
        const occupied = {};

        for (const ws of Hyprland.workspaces.values) {
            if (workspaceBelongsHere(ws) && ws.lastIpcObject.windows > 0)
                occupied[ws.id] = true;
        }

        for (const client of Hyprland.toplevels.values) {
            const ws = client.workspace;
            if (workspaceBelongsHere(ws))
                occupied[ws.id] = true;
        }

        return occupied;
    }

    readonly property var shownWorkspaceIds: {
        refreshToken;
        const ids = {};

        for (const id of assignedWorkspaceIds) {
            if (id > 0)
                ids[id] = true;
        }

        if (activeWorkspaceId > 0)
            ids[activeWorkspaceId] = true;

        // Hyprland.workspaces usually contains active and occupied workspaces.
        // Include every workspace currently reported on this monitor so
        // non-default active workspaces (e.g. 4 on HDMI-A-1) appear on that
        // monitor's topbar even when they are outside the default assignment.
        for (const ws of Hyprland.workspaces.values) {
            if (workspaceBelongsHere(ws))
                ids[ws.id] = true;
        }

        for (const id in occupiedWorkspaces)
            ids[id] = true;

        return Object.keys(ids).map(id => Number(id)).sort((a, b) => a - b);
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (["workspace", "moveworkspace", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                root.refreshToken++;
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
                root.refreshToken++;
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
                root.refreshToken++;
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
                root.refreshToken++;
            }
        }
    }

    // --- DECORATIVE: WORKSPACES LABEL (Vertical) ---
    Item {
        Layout.preferredWidth: 8
        Layout.fillHeight: true
        
        Text {
            anchors.centerIn: parent
            text: "WS"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: root.accentColor
            opacity: 0.5
            rotation: -90
            width: 30
            horizontalAlignment: Text.AlignHCenter
        }

        // Vertical anchor bar
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 1; height: parent.height - 8
            color: root.accentColor
            opacity: 0.2
        }
    }

    Row {
        spacing: 10
        Repeater {
            model: root.shownWorkspaceIds
            delegate: Rectangle {
                id: wsRect
                property int wsId: modelData
                property var workspace: Hyprland.workspaces.values.find(w => w.id === wsId)
                property bool isFocused: root.activeWorkspaceId === wsId
                property bool hasWindows: root.occupiedWorkspaces[wsId] === true
                property string workspaceTitle: {
                    if (isFocused && Hyprland.activeToplevel?.workspace?.id === wsId)
                        return Hyprland.activeToplevel.title || "UNKNOWN";

                    return workspace?.lastIpcObject?.lastwindowtitle || "";
                }
                
                visible: true
                
                width: {
                    if (isFocused && Hyprland.activeToplevel) {
                        return Math.min(240, Math.max(72, textureText.implicitWidth + 48));
                    }
                    return 18; // Highly collapsed inactive tab
                }
                height: 32 
                radius: 2
                clip: true
                
                color: isFocused ? root.accentColor : Services.Theme.surfaceLighter
                border.width: 1
                border.color: isFocused ? root.accentColor : Services.Theme.border

                // --- CORNER ACCENT: FOCUSED ---
                Rectangle {
                    visible: wsRect.isFocused
                    width: 5; height: 5
                    anchors.top: parent.top
                    anchors.left: parent.left
                    color: root.accentColor
                    z: 10
                    
                    // Cutout effect
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: root.bgColor
                    }
                }

                // --- TEXT CONTENT: NUMBER & TITLE ---
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: wsRect.isFocused ? 10 : 0
                    spacing: 8
                    
                    // Workspace Number (Centered if inactive)
                    Text {
                        text: wsId
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.bold: true
                        color: wsRect.isFocused ? root.bgColor : root.mutedColor
                        opacity: wsRect.isFocused ? 1 : 0.8
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: !wsRect.isFocused
                        horizontalAlignment: wsRect.isFocused ? Text.AlignLeft : Text.AlignHCenter
                    }

                    // Divider Line
                    Rectangle {
                        visible: wsRect.isFocused
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 12
                        color: root.bgColor
                        opacity: 0.3
                    }

                    // Window Title (Information as Texture)
                    GlitchText {
                        id: textureText
                        visible: wsRect.isFocused
                        Layout.fillWidth: true
                        Layout.rightMargin: 8
                        
                        textData: wsRect.isFocused && wsRect.workspaceTitle ? wsRect.workspaceTitle.toUpperCase() : ""
                        periodicInterval: 25000 + Math.random() * 10000
                        totalTicks: 12

                        font.pixelSize: 11
                        font.bold: true
                        color: root.bgColor
                        opacity: 0.4
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsId)
                }
                
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }
}
