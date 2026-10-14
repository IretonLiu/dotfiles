import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.rightMargin: 10

    required property ShellScreen screen

    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted
    property color bgColor: Services.Theme.surface

    // HyprState parses the workspace monitor rules from hyprland.conf, keeping
    // the bar's placeholder tabs in sync with the compositor configuration.
    readonly property int refreshToken: Services.HyprState.refreshToken

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property string monitorName: monitor?.name ?? screen.name
    readonly property int activeWorkspaceId: {
        refreshToken;
        if (Hyprland.focusedMonitor?.name === monitorName)
            return Hyprland.focusedWorkspace?.id ?? 0;

        return monitor?.activeWorkspace?.id ?? monitor?.lastIpcObject?.activeWorkspace?.id ?? 0;
    }
    readonly property var assignedWorkspaceIds: {
        refreshToken;
        return Services.HyprState.assignmentsFor(monitorName);
    }

    // The focused tab contains the active window name. Keep it compact on
    // normal displays, but allow proportionally more context on wide screens.
    readonly property real maxFocusedWorkspaceWidth: Math.round(Math.max(160, Math.min(320, screen.width * 0.10)))

    function workspaceMonitorName(ws) {
        const monitor = ws?.monitor ?? ws?.lastIpcObject?.monitor ?? ws?.lastIpcObject?.monitorName ?? "";
        return typeof monitor === "string" ? monitor : (monitor?.name ?? "");
    }

    function workspaceBelongsHere(ws) {
        if (!ws || ws.id <= 0 || ws.name.startsWith("special:"))
            return false;

        return workspaceMonitorName(ws) === monitorName;
    }

    function shouldShowAssignedWorkspace(id) {
        const workspace = Hyprland.workspaces.values.find(ws => ws.id === id);
        const owner = workspaceMonitorName(workspace);

        // Show an empty rule-assigned workspace as a placeholder, but never
        // mirror a workspace that Hyprland says currently lives elsewhere.
        return !workspace || owner === "" || owner === monitorName;
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
            if (id > 0 && shouldShowAssignedWorkspace(id))
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
                    if (!isFocused)
                        return workspace?.lastIpcObject?.lastwindowtitle || "";

                    if (Hyprland.activeToplevel?.workspace?.id === wsId)
                        return Hyprland.activeToplevel.title || "WINDOW_ACTIVE";
                    if (hasWindows)
                        return workspace?.lastIpcObject?.lastwindowtitle || "WINDOWS_ACTIVE";
                    return "EMPTY_WORKSPACE";
                }

                visible: true

                width: isFocused ? Math.min(root.maxFocusedWorkspaceWidth, Math.max(72, textureText.implicitWidth + 48)) : 18
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
                        font.pixelSize: 13
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

                        font.pixelSize: 12
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
