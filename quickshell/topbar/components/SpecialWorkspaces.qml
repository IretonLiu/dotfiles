import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services" as Services

Item {
    id: root

    required property ShellScreen screen
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted
    property color bgColor: Services.Theme.surface

    implicitWidth: specialLabel.width + buttonRow.width + 16
    implicitHeight: 32

    readonly property int refreshToken: Services.HyprState.refreshToken
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property string monitorName: monitor?.name ?? screen.name
    readonly property string activeSpecialName: {
        refreshToken;
        return monitor?.lastIpcObject?.specialWorkspace?.name ?? "";
    }

    function toggleSpecialWorkspace(name) {
        // Special workspaces attach to a monitor. Select the monitor behind the
        // clicked bar first, then open or close the requested overlay.
        Hyprland.dispatch("focusmonitor " + monitorName);
        Qt.callLater(() => Hyprland.dispatch("togglespecialworkspace " + name));
    }

    Item {
        id: specialLabel
        width: 8
        height: parent.height

        Text {
            anchors.centerIn: parent
            text: "SP"
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            color: root.accentColor
            opacity: 0.5
            rotation: -90
            width: 30
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 8
            color: root.accentColor
            opacity: 0.2
        }
    }

    Row {
        id: buttonRow
        anchors.left: specialLabel.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: [
                { "name": "music", "label": "MUSIC", "icon": "󰎆" },
                { "name": "email", "label": "MAIL", "icon": "󰇮" }
            ]

            delegate: MouseArea {
                id: specialButton

                required property var modelData
                readonly property string workspaceName: "special:" + modelData.name
                readonly property var workspace: {
                    root.refreshToken;
                    return Hyprland.workspaces.values.find(ws => ws.name === workspaceName) ?? null;
                }
                readonly property bool active: root.activeSpecialName === workspaceName
                readonly property bool occupied: (workspace?.lastIpcObject?.windows ?? 0) > 0

                width: 28
                height: 32
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: root.toggleSpecialWorkspace(modelData.name)

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: specialButton.active ? root.accentColor : Services.Theme.surfaceLighter
                    border.width: 1
                    border.color: specialButton.active ? root.accentColor : Services.Theme.border

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }

                // Match the corner marker used by the focused normal-workspace tab.
                Rectangle {
                    visible: specialButton.active
                    width: 5
                    height: 5
                    anchors.top: parent.top
                    anchors.left: parent.left
                    color: root.accentColor
                    z: 2

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: root.bgColor
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: specialButton.modelData.icon
                    font.family: "JetBrains Mono"
                    font.pixelSize: 17
                    color: specialButton.active ? root.bgColor : root.accentColor
                }

                // A small activity marker mirrors the normal workspace's window state
                // without giving the special tab a different visual hierarchy.
                Rectangle {
                    visible: specialButton.occupied && !specialButton.active
                    width: 3
                    height: 3
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 3
                    color: Services.Theme.success
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: root.accentColor
                    opacity: specialButton.containsMouse && !specialButton.active ? 0.1 : 0
                }

            }
        }
    }
}
