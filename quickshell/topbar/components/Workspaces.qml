import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.leftMargin: 10
    Layout.rightMargin: 10

    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted
    property color bgColor: Services.Theme.surface

    // Hyprland.workspaces can miss/lag the window count in some cases, and the
    // old fixed `model: 10` silently dropped occupied workspaces above 10.
    // Build the shown ids from both workspace IPC data and live toplevels.
    readonly property var occupiedWorkspaces: {
        const occupied = {};

        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && !ws.name.startsWith("special:") && ws.lastIpcObject.windows > 0)
                occupied[ws.id] = true;
        }

        for (const client of Hyprland.toplevels.values) {
            const id = client.workspace?.id;
            if (id > 0)
                occupied[id] = true;
        }

        return occupied;
    }

    readonly property var shownWorkspaceIds: {
        const ids = {};

        const focusedId = Hyprland.focusedWorkspace?.id ?? 1;
        if (focusedId > 0)
            ids[focusedId] = true;

        for (const id in occupiedWorkspaces)
            ids[id] = true;

        return Object.keys(ids).map(id => Number(id)).sort((a, b) => a - b);
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
                property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
                property bool hasWindows: root.occupiedWorkspaces[wsId] === true
                
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
                        
                        textData: isFocused && Hyprland.activeToplevel ? (Hyprland.activeToplevel.title || "UNKNOWN").toUpperCase() : ""
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
