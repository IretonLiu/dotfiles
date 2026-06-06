import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services" as Services

FlowMenu {
    id: root
    verticalLabel: "NET"

    Process {
        id: shellCommand
        function run(args) {
            command = args
            running = true
        }
    }
    
    function getNetworkIcon(strength) {
        if (!Services.Nmcli.isConnected) return "󰤮";
        if (strength >= 80) return "󰤨";
        if (strength >= 60) return "󰤥";
        if (strength >= 40) return "󰤢";
        if (strength >= 20) return "󰤟";
        return "󰤯";
    }

    ColumnLayout {
        spacing: 14
        
        // Header
        RowLayout {
            spacing: 12
            Column {
                spacing: -2
                Text {
                    text: "NETWORK_STATUS"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: Services.Theme.highlight
                }
                Text {
                    text: Services.Nmcli.activeInterface || "Unknown Interface"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: Services.Theme.muted
                    Layout.preferredWidth: 210
                    elide: Text.ElideRight
                }
            }
        }
        
        // nmtui Action Button
        MouseArea {
            id: nmtuiBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onClicked: {
                shellCommand.run(["alacritty", "--class", "floating", "-e", "nmtui"])
            }

            property bool showHighlight: containsMouse
            readonly property bool isConnected: Services.Nmcli.isConnected
            readonly property color baseColor: isConnected ? Services.Theme.success : Services.Theme.danger
            
            Rectangle {
                id: highlightFrame
                anchors.centerIn: parent
                width: parent.width + (nmtuiBtn.showHighlight ? 4 : -4)
                height: parent.height + (nmtuiBtn.showHighlight ? 4 : -4)
                opacity: nmtuiBtn.showHighlight ? 0.3 : 0
                color: "transparent"
                border.width: 1
                border.color: nmtuiBtn.baseColor
                radius: 4
                
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 300 } }

                Repeater {
                    model: 4
                    Rectangle {
                        width: 4; height: 4
                        color: nmtuiBtn.baseColor
                        opacity: highlightFrame.opacity * 2
                        
                        anchors.top: index < 2 ? parent.top : undefined
                        anchors.bottom: index >= 2 ? parent.bottom : undefined
                        anchors.left: index % 2 == 0 ? parent.left : undefined
                        anchors.right: index % 2 != 0 ? parent.right : undefined
                        anchors.margins: -1
                    }
                }
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 16
                
                Text {
                    text: "["
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: Services.Theme.muted
                }
                
                Column {
                    spacing: -2
                    
                    Text {
                        text: nmtuiBtn.isConnected ? "CONNECTED" : "DISCONNECTED"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: true
                        color: nmtuiBtn.baseColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: Services.Nmcli.active?.ssid ?? (nmtuiBtn.isConnected ? "Wired Connection" : "None")
                        font.family: "JetBrains Mono"
                        font.pixelSize: 7
                        font.weight: Font.Bold
                        color: Services.Theme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Text {
                    text: "]"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: Services.Theme.muted
                }
            }
            
            Rectangle {
                anchors.fill: parent
                color: nmtuiBtn.baseColor
                opacity: parent.containsMouse ? 0.1 : 0
                radius: 4
            }
        }
        
        Text {
            text: Services.Nmcli.scanning ? "SCANNING_FOR_AP..." : "NETWORK_READY"
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.muted
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 2
        }
    }
}
