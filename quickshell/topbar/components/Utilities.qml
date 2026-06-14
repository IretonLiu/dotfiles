import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.leftMargin: 10
    Layout.rightMargin: 10

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    // Signal to notify shell.qml about menu toggles
    signal menuToggle(string name)

    // Export buttons so shell.qml can anchor menus to them
    property alias audioBtn: audioBtn
    property alias netBtn: netBtn
    property alias themeBtn: themeBtn
    property alias btBtn: btBtn
    property alias wgBtn: wgBtn
    property alias powerBtn: powerBtn

    Process {
        id: shellCommand
        function run(args) {
            command = args
            running = true
        }
    }

    // --- DECORATIVE: UTILITIES LABEL (Vertical) ---
    Item {
        Layout.preferredWidth: 8
        Layout.fillHeight: true
        
        Text {
            anchors.centerIn: parent
            text: "SYS"
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

    function getNetworkIcon(strength) {
        if (!Services.Nmcli.isConnected) return "󰤮";
        if (strength >= 80) return "󰤨";
        if (strength >= 60) return "󰤥";
        if (strength >= 40) return "󰤢";
        if (strength >= 20) return "󰤟";
        return "󰤯";
    }

    component UtilityButton: MouseArea {
        id: buttonRoot
        property string icon: ""
        property int iconSize: 24
        property string label: ""
        property string sublabel: ""
        property color iconColor: root.accentColor
        property bool active: false
        
        implicitWidth: contentRow.implicitWidth + 16
        implicitHeight: 32
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        // --- HIGHLIGHT ANIMATION ---
        property bool showHighlight: containsMouse || active
        
        Rectangle {
            id: highlightFrame
            anchors.centerIn: parent
            width: parent.width + (showHighlight ? 4 : -4)
            height: parent.height + (showHighlight ? 4 : -4)
            opacity: showHighlight ? 0.3 : 0
            color: "transparent"
            border.width: 1
            border.color: iconColor
            radius: 4
            
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            // Scanning corner accents
            Repeater {
                model: 4
                Rectangle {
                    width: 4; height: 4
                    color: buttonRoot.iconColor
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
            id: contentRow
            anchors.centerIn: parent
            spacing: 12
            
            Text {
                text: icon
                font.family: "JetBrains Mono"
                font.pixelSize: buttonRoot.iconSize
                color: iconColor
                Layout.alignment: Qt.AlignVCenter
            }
            
            Column {
                spacing: -2
                visible: label !== ""
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    text: label
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.textColor
                }
                
                Text {
                    text: sublabel
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: root.mutedColor
                    visible: sublabel !== ""
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: Services.Theme.accent
            opacity: parent.containsMouse ? 0.1 : 0
            radius: 4
        }
    }

    // --- SOUND ---
    UtilityButton {
        id: audioBtn
        icon: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? "󰝟" : "󰕾"
        label: Math.round((Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0) * 100) + "%"
        sublabel: "AUDIO_SINK"
        active: rootWindow.activeMenu === "audio"
        onClicked: root.menuToggle("audio")
    }

    // --- NETWORK ---
    UtilityButton {
        id: netBtn
        icon: root.getNetworkIcon(Services.Nmcli.active ? Services.Nmcli.active.strength : 0)
        label: Services.Nmcli.isConnected ? (Services.Nmcli.active ? Services.Nmcli.active.ssid : "CONNECTED") : "OFFLINE"
        sublabel: Services.Nmcli.activeInterface || "NET_DOWN"
        active: rootWindow.activeMenu === "network"
        onClicked: root.menuToggle("network")
    }

    // --- WIREGUARD ---
    UtilityButton {
        id: wgBtn
        icon: "󰖂"
        iconSize: 20
        label: Services.Vpn.connected ? "SECURE" : "UNSECURE"
        sublabel: Services.Vpn.connected ? Services.Vpn.activeInterface.toUpperCase() : "VPN_OFF"
        iconColor: Services.Vpn.connected ? Services.Theme.success : root.accentColor
        active: rootWindow.activeMenu === "vpn"
        onClicked: root.menuToggle("vpn")
    }

    // --- THEME TOGGLE ---
    UtilityButton {
        id: themeBtn
        icon: Services.Theme.isLightMode ? "󰃠" : "󰃽"
        iconSize: 20
        label: Services.Theme.isLightMode ? "LIGHT" : "DARK"
        sublabel: "UI_THEME"
        onClicked: Services.Theme.toggle()
    }

    // --- BLUETOOTH ---
    UtilityButton {
        id: btBtn
        icon: "󰂯"
        iconSize: 20
        label: "BLUETOOTH"
        sublabel: "BT_SERVICE"
        onClicked: shellCommand.run(["hyprctl", "dispatch", "exec", "[float] blueman-manager"])
    }

    // --- POWER ---
    UtilityButton {
        id: powerBtn
        icon: "󰐥"
        label: ""
        sublabel: ""
        iconColor: Services.Theme.danger
        active: rootWindow.activeMenu === "power"
        onClicked: root.menuToggle("power")
    }
}
