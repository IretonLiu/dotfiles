import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services" as Services

RowLayout {
    id: root
    spacing: 9
    Layout.leftMargin: 10
    Layout.rightMargin: 10

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    // Signals to notify shell.qml about menu toggles and launch failures.
    signal menuToggle(string name)
    signal statusRequested(string message)

    // Export buttons so shell.qml can anchor menus to them
    property alias audioBtn: audioBtn
    property alias focusBtn: focusBtn
    property alias netBtn: netBtn
    property alias themeBtn: themeBtn
    property alias btBtn: btBtn
    property alias wgBtn: wgBtn
    property alias powerBtn: powerBtn

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

    component UtilityButton: MouseArea {
        id: buttonRoot
        property string icon: ""
        property int iconSize: 25
        property string label: ""
        property string sublabel: ""
        property int labelMaxWidth: 116
        property color iconColor: root.accentColor
        property bool showDetails: true
        property bool detailsAlwaysVisible: false
        property bool active: false
        property bool solidActive: false
        signal activated()
        signal contextActivated()

        // All tools stay compact at rest and reveal their full readout only
        // while hovered, preserving a symmetric icon rail.
        property bool expanded: showDetails && (detailsAlwaysVisible || containsMouse)
        readonly property real collapsedWidth: Math.max(32, collapsedIcon.implicitWidth + 16)
        readonly property real expandedWidth: Math.max(collapsedWidth, iconGlyph.implicitWidth + detailColumn.textWidth + 28)

        Layout.preferredWidth: expanded ? expandedWidth : collapsedWidth
        Layout.minimumWidth: collapsedWidth
        Layout.maximumWidth: expandedWidth
        implicitWidth: Layout.preferredWidth
        implicitHeight: 32
        // The shared frame must be allowed to grow outside the button. Text is
        // clipped separately in contentViewport while the width animates.
        clip: false
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: forceActiveFocus()
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                contextActivated()
            else
                activated()
        }
        Keys.onReturnPressed: event => {
            event.accepted = true
            activated()
        }
        Keys.onEnterPressed: event => {
            event.accepted = true
            activated()
        }
        Keys.onSpacePressed: event => {
            event.accepted = true
            activated()
        }

        // --- HIGHLIGHT ANIMATION ---
        property bool showHighlight: containsMouse || active

        AnimatedAccentFrame {
            active: buttonRoot.showHighlight
            accentColor: buttonRoot.solidActive && buttonRoot.active ? Services.Theme.surface : buttonRoot.iconColor
            z: 2
        }

        Rectangle {
            anchors.fill: parent
            color: buttonRoot.iconColor
            opacity: buttonRoot.solidActive && buttonRoot.active ? 1 : 0
            radius: 4

            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        Item {
            id: contentViewport
            anchors.fill: parent
            clip: true
            z: 1

            Text {
                id: collapsedIcon
                anchors.centerIn: parent
                text: buttonRoot.icon
                visible: !buttonRoot.expanded && detailColumn.opacity <= 0.01
                font.family: "JetBrains Mono"
                font.pixelSize: buttonRoot.iconSize
                color: buttonRoot.solidActive && buttonRoot.active ? Services.Theme.surface : buttonRoot.iconColor
            }

            RowLayout {
                id: fullContent
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                visible: label !== "" && (buttonRoot.expanded || detailColumn.opacity > 0.01)

                Text {
                    id: iconGlyph
                    text: icon
                    font.family: "JetBrains Mono"
                    font.pixelSize: buttonRoot.iconSize
                    color: buttonRoot.solidActive && buttonRoot.active ? Services.Theme.surface : iconColor
                    opacity: detailColumn.opacity
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    id: detailColumn
                    spacing: -2
                    readonly property real textWidth: Math.min(detailLabel.implicitWidth, buttonRoot.labelMaxWidth)
                    width: textWidth
                    opacity: buttonRoot.expanded ? 1 : 0
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Text {
                        id: detailLabel
                        width: parent.width
                        text: label
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        font.bold: true
                        color: buttonRoot.solidActive && buttonRoot.active ? Services.Theme.surface : root.textColor
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: sublabel
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: buttonRoot.solidActive && buttonRoot.active ? Services.Theme.surface : root.mutedColor
                        opacity: buttonRoot.solidActive && buttonRoot.active ? 0.8 : 1
                        visible: sublabel !== ""
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: buttonRoot.solidActive && buttonRoot.active ? Services.Theme.surface : Services.Theme.accent
            opacity: parent.containsMouse ? 0.1 : 0
            radius: 4
            z: 1.5
        }
    }

    // --- FOCUS MODE ---
    UtilityButton {
        id: focusBtn
        icon: "󰐷"
        iconSize: 21
        label: "FOCUS_MODE"
        sublabel: Services.Dunst.paused ? "DND_ACTIVE" : "DND_OFF"
        iconColor: Services.Dunst.paused ? Services.Theme.warning : root.accentColor
        active: Services.Dunst.paused
        solidActive: true
        onActivated: {
            if (Services.Dunst.available)
                Services.Dunst.toggle()
            else
                root.statusRequested(Services.Dunst.lastError || "Dunst is unavailable.")
        }
        onContextActivated: root.menuToggle("focusAudio")

        ToolTip.visible: containsMouse
        ToolTip.text: "CLICK: TOGGLE FOCUS · RIGHT CLICK: FOCUS AUDIO"
        ToolTip.delay: 700
    }

    // --- SOUND ---
    UtilityButton {
        id: audioBtn
        icon: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted) ? "󰝟" : "󰕾"
        label: Math.round((Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0) * 100) + "%"
        sublabel: "AUDIO_SINK"
        active: rootWindow.activeMenu === "audio"
        onActivated: root.menuToggle("audio")
    }

    // --- NETWORK ---
    UtilityButton {
        id: netBtn
        icon: root.getNetworkIcon(Services.Nmcli.active ? Services.Nmcli.active.strength : 0)
        label: Services.Nmcli.isConnected ? (Services.Nmcli.active ? Services.Nmcli.active.ssid : "CONNECTED") : "OFFLINE"
        labelMaxWidth: 112
        sublabel: Services.Nmcli.activeInterface || "NET_DOWN"
        active: rootWindow.activeMenu === "network"
        onActivated: root.menuToggle("network")
    }

    // --- WIREGUARD ---
    UtilityButton {
        id: wgBtn
        icon: "󰖂"
        iconSize: 21
        label: Services.Vpn.connected ? "SECURE" : "UNSECURE"
        sublabel: Services.Vpn.connected ? Services.Vpn.activeInterface.toUpperCase() : "VPN_OFF"
        iconColor: Services.Vpn.connected ? Services.Theme.success : root.accentColor
        active: rootWindow.activeMenu === "vpn"
        onActivated: root.menuToggle("vpn")
    }

    // --- THEME TOGGLE ---
    UtilityButton {
        id: themeBtn
        icon: Services.Theme.isLightMode ? "󰃠" : "󰃽"
        iconSize: 21
        label: Services.Theme.isLightMode ? "LIGHT" : "DARK"
        sublabel: "UI_THEME"
        onActivated: Services.Theme.toggle()
    }

    // --- BLUETOOTH ---
    UtilityButton {
        id: btBtn
        icon: "󰂯"
        iconSize: 21
        label: "BLUETOOTH"
        sublabel: "BT_SERVICE"
        onActivated: shellCommand.run(["alacritty", "--class", "floating", "-e", "bluetui"], "bluetui")
    }

    // --- POWER ---
    UtilityButton {
        id: powerBtn
        icon: "󰐥"
        label: "POWER"
        sublabel: "SESSION_MENU"
        iconColor: Services.Theme.danger
        active: rootWindow.activeMenu === "power"
        onActivated: root.menuToggle("power")
    }
}
