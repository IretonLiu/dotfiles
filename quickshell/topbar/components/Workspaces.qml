import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../services" as Services

RowLayout {
    id: root
    spacing: 6

    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted
    property color bgColor: Services.Theme.surface

    Repeater {
        model: 10
        delegate: Rectangle {
            id: wsRect
            width: 30 
            height: 28 
            radius: 3
            
            property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1
            
            color: isFocused ? root.accentColor : Services.Theme.surfaceLighter
            border.width: 1
            border.color: isFocused ? root.accentColor : Services.Theme.border

            Column {
                anchors.centerIn: parent
                spacing: 1
                
                Text {
                    text: "0" + (index + 1)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: wsRect.isFocused ? root.bgColor : root.mutedColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: wsRect.isFocused ? 1 : 0.8
                }
                
                Rectangle {
                    width: 4; height: 3
                    radius: 1
                    color: wsRect.isFocused ? root.bgColor : root.accentColor
                    opacity: wsRect.isFocused ? 1 : 0.4
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
            }
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
