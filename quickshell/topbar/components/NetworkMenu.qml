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
        property string commandLabel: ""

        function run(args, label) {
            commandLabel = label || args[0]
            command = args
            running = true
        }

        onExited: code => {
            if (code !== 0)
                root.statusRequested(commandLabel + " failed (exit " + code + ")")
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
                    font.pixelSize: 12
                    font.bold: true
                    color: Services.Theme.highlight
                }
                Text {
                    text: Services.Nmcli.activeInterface || "Unknown Interface"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
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
            activeFocusOnTab: true
            onPressed: forceActiveFocus()

            function openNetworkTui() {
                shellCommand.run(["alacritty", "--class", "floating", "-e", "nmtui"], "nmtui")
                root.closeRequested()
            }

            onClicked: openNetworkTui()
            Keys.onReturnPressed: event => { event.accepted = true; openNetworkTui(); }
            Keys.onEnterPressed: event => { event.accepted = true; openNetworkTui(); }
            Keys.onSpacePressed: event => { event.accepted = true; openNetworkTui(); }

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
                    font.pixelSize: 12
                    font.bold: true
                    color: Services.Theme.muted
                }
                
                Column {
                    spacing: -2
                    
                    Text {
                        text: nmtuiBtn.isConnected ? "CONNECTED" : "DISCONNECTED"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.bold: true
                        color: nmtuiBtn.baseColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: Services.Nmcli.active?.ssid ?? (nmtuiBtn.isConnected ? "Wired Connection" : "None")
                        font.family: "JetBrains Mono"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: Services.Theme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Text {
                    text: "]"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
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
        
        MouseArea {
            id: scanButton
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            activeFocusOnTab: true
            onPressed: forceActiveFocus()

            function scan() {
                if (!Services.Nmcli.scanning)
                    Services.Nmcli.rescanWifi()
            }

            onClicked: scan()
            Keys.onReturnPressed: event => { event.accepted = true; scan(); }
            Keys.onEnterPressed: event => { event.accepted = true; scan(); }
            Keys.onSpacePressed: event => { event.accepted = true; scan(); }

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: root.accentColor
                opacity: scanButton.containsMouse ? 0.12 : 0.04
            }

            Text {
                anchors.centerIn: parent
                text: Services.Nmcli.scanning ? "SCANNING_FOR_AP..." : "SCAN_NETWORKS"
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                font.bold: true
                color: Services.Nmcli.scanning ? Services.Theme.warning : Services.Theme.highlight
            }
        }
    }
}
