import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../services" as Services

RowLayout {
    id: root
    spacing: 12

    property color textColor: "#0F172A"
    property color accentColor: "#334155"
    property color mutedColor: "#94A3B8"
    
    // Signal to notify shell.qml about menu toggles
    signal menuToggle(string name)

    // Export buttons so shell.qml can anchor menus to them
    property alias audioBtn: audioBtn
    property alias netBtn: netBtn
    property alias powerBtn: powerBtn

    function getNetworkIcon(strength) {
        if (!Services.Nmcli.isConnected) return "󰤮";
        if (strength >= 80) return "󰤨";
        if (strength >= 60) return "󰤥";
        if (strength >= 40) return "󰤢";
        if (strength >= 20) return "󰤟";
        return "󰤯";
    }

    component UtilityButton: MouseArea {
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property color iconColor: root.accentColor
        
        implicitWidth: contentRow.implicitWidth + 12
        implicitHeight: 28
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 10
            
            Text {
                text: icon
                font.family: "JetBrains Mono"
                font.pixelSize: 24
                color: iconColor
            }
            
            Column {
                spacing: -2
                visible: label !== ""
                
                Text {
                    text: label
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.textColor
                }
                
                Text {
                    text: sublabel
                    font.family: "JetBrains Mono"
                    font.pixelSize: 7
                    font.weight: Font.Bold
                    color: root.mutedColor
                    visible: sublabel !== ""
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: root.accentColor
            opacity: parent.containsMouse ? 0.05 : 0
            radius: 4
        }
    }

    // --- SOUND ---
    UtilityButton {
        id: audioBtn
        icon: (Pipewire.defaultAudioSink?.audio?.muted) ? "󰝟" : "󰕾"
        label: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"
        sublabel: "AUDIO_SINK"
        onClicked: root.menuToggle("audio")
    }

    // --- NETWORK ---
    UtilityButton {
        id: netBtn
        icon: root.getNetworkIcon(Services.Nmcli.active?.strength ?? 0)
        label: Services.Nmcli.isConnected ? (Services.Nmcli.active?.ssid ?? "CONNECTED") : "OFFLINE"
        sublabel: Services.Nmcli.activeInterface || "NET_DOWN"
        onClicked: root.menuToggle("network")
    }

    // --- POWER ---
    UtilityButton {
        id: powerBtn
        icon: "󰐥"
        label: "OFF"
        sublabel: "SYS_HALT"
        iconColor: "#EF4444"
        onClicked: root.menuToggle("power")
    }
}
