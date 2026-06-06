import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as Services

FlowMenu {
    id: root
    
    function getNetworkIcon(strength) {
        if (!Services.Nmcli.isConnected) return "󰤮";
        if (strength >= 80) return "󰤨";
        if (strength >= 60) return "󰤥";
        if (strength >= 40) return "󰤢";
        if (strength >= 20) return "󰤟";
        return "󰤯";
    }

    ColumnLayout {
        spacing: 12
        Layout.margins: 10
        
        RowLayout {
            spacing: 12
            Text {
                text: root.getNetworkIcon(Services.Nmcli.active?.strength ?? 0)
                font.family: "JetBrains Mono"
                font.pixelSize: 28 
                color: root.accentColor
            }
            Text {
                text: "NETWORK_STATUS"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.bold: true
                color: Services.Theme.highlight
            }
        }
        
        Rectangle {
            Layout.preferredWidth: contentWrapper.implicitWidth + 32
            Layout.preferredHeight: 40
            color: Services.Theme.surfaceLighter
            radius: 4
            
            RowLayout {
                id: contentWrapper
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10
                
                Rectangle {
                    width: 8; height: 8
                    radius: 4
                    color: Services.Nmcli.isConnected ? Services.Theme.success : Services.Theme.danger 
                }
                
                Column {
                    Text {
                        text: Services.Nmcli.isConnected ? "CONNECTED" : "DISCONNECTED"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                        color: Services.Nmcli.isConnected ? Services.Theme.success : Services.Theme.danger
                    }
                    Text {
                        text: Services.Nmcli.active?.ssid ?? (Services.Nmcli.isConnected ? "Wired Connection" : "None")
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: true
                        color: Services.Theme.highlight
                    }
                }
            }
        }
        
        Text {
            text: Services.Nmcli.scanning ? "SCANNING_FOR_AP..." : "NETWORK_READY"
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.muted
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
