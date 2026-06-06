import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../services" as Services

RowLayout {
    id: root
    spacing: 12
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted
    property color bgColor: Services.Theme.surface

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
        spacing: 8
        Repeater {
            model: 10
            delegate: Rectangle {
                id: wsRect
                property int wsId: index + 1
                property var workspace: Hyprland.workspaces.values.find(w => w.id === wsId)
                property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
                property bool hasWindows: workspace ? workspace.lastIpcObject.windows > 0 : false
                
                visible: isFocused || hasWindows
                
                width: {
                    if (!visible) return 0;
                    if (isFocused && Hyprland.activeToplevel) {
                        return Math.min(220, Math.max(64, textureText.implicitWidth + 40));
                    }
                    return 16; // Highly collapsed inactive tab
                }
                height: 30 
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
                        font.pixelSize: 11
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

                        font.pixelSize: 10
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
