import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "services" as Services
import "components"

ShellRoot {
    // FocusAudio owns the per-application mute guard; Dunst remains the
    // source of truth for whether Focus Mode is currently enabled.
    Connections {
        target: Services.Dunst
        function onPausedChanged() {
            Services.FocusAudio.setFocusActive(Services.Dunst.paused)
        }
    }

    Process {
        id: polkitAgent

        running: true
        command: ["systemctl", "--user", "start", "hyprpolkitagent.service"]
    }
    
    // --- PIPEWIRE TRACKING ---
    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource
        ]
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: rootWindow
            required property ShellScreen modelData

            screen: modelData

            anchors {
        top: true
        left: true
        right: true
    }
    
    implicitHeight: screen.height 
    WlrLayershell.exclusiveZone: 50
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: rootWindow.activeMenu !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        width: rootWindow.width
        height: rootWindow.activeMenu !== "" ? rootWindow.height : barContainer.height
    }
    
    color: "transparent"

    // Global Close Handler
    MouseArea {
        anchors.fill: parent
        enabled: rootWindow.activeMenu !== ""
        onPressed: rootWindow.activeMenu = ""
        z: 0 
    }

            property string activeMenu: ""
            property string statusMessage: ""

            function showStatus(message) {
                statusMessage = message
                statusTimer.restart()
            }

            Timer {
                id: statusTimer
                interval: 3500
                onTriggered: rootWindow.statusMessage = ""
            }

    // The Bar Island Container
    property int barHeight: 46
    
    Item {
        id: barContainer
        height: rootWindow.barHeight
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 3
        z: 10 

        // --- LEFT: SYSTEM MONITOR, CLOCK & MEDIA ---
        Item {
            id: leftGroup
            readonly property real spacing: 8
            readonly property real minimumContentWidth: clockIsland.implicitWidth + systemIsland.implicitWidth + spacing

            anchors.left: parent.left
            anchors.right: workspaceIsland.left
            anchors.rightMargin: spacing
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            clip: true
            
            TopbarIsland {
                id: clockIsland
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: rootWindow.barHeight - 2
                title: "CLK"
                Clock {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                }
            }

            TopbarIsland {
                id: systemIsland
                anchors.left: clockIsland.right
                anchors.leftMargin: leftGroup.spacing
                anchors.verticalCenter: parent.verticalCenter
                height: rootWindow.barHeight - 2
                title: "TLM"
                SystemMonitor {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                }
            }

            TopbarIsland {
                id: mediaIsland
                anchors.left: systemIsland.right
                anchors.leftMargin: leftGroup.spacing
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(248, Math.max(0, leftGroup.width - x))
                height: rootWindow.barHeight - 2
                title: "MSC"
                visible: Services.Media.active !== null && width >= 144
                clip: true
                MediaPlayer {
                    Layout.preferredWidth: mediaIsland.contentAvailableWidth
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                }
            }
        }

        // --- CENTER: WORKSPACES ---
        TopbarIsland {
            id: workspaceIsland
            readonly property real maxCenteredWidth: Math.max(0, 2 * Math.min(parent.width / 2 - leftGroup.minimumContentWidth - 8, rightGroup.x - parent.width / 2 - 8))

            anchors.centerIn: parent
            height: rootWindow.barHeight - 2
            width: Math.min(implicitWidth, maxCenteredWidth)
            visible: width >= 40
            title: "WS"
            clip: true
            Workspaces {
                screen: rootWindow.screen
                accentColor: Services.Theme.accent
                mutedColor: Services.Theme.muted
                bgColor: Services.Theme.surface
            }

            SpecialWorkspaces {
                screen: rootWindow.screen
                Layout.leftMargin: 8
                accentColor: Services.Theme.accent
                mutedColor: Services.Theme.muted
                bgColor: Services.Theme.surface
            }
        }

        // --- RIGHT: UTILITIES & CLOCK ---
        RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: 16
            
            TopbarIsland {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: rootWindow.barHeight - 2
                title: "SYS"
                Utilities {
                    id: utils
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                    onMenuToggle: name => {
                        if (rootWindow.activeMenu === name) rootWindow.activeMenu = ""
                        else rootWindow.activeMenu = name
                    }
                    onStatusRequested: message => rootWindow.showStatus(message)
                }
            }
        }
    }
    
    Rectangle {
        id: statusToast
        anchors.top: barContainer.bottom
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: Math.min(parent.width - 32, statusText.implicitWidth + 32)
        height: statusText.implicitHeight + 18
        radius: 4
        color: Services.Theme.surface
        border.width: 1
        border.color: Services.Theme.danger
        visible: rootWindow.statusMessage !== ""
        z: 30

        Text {
            id: statusText
            anchors.centerIn: parent
            width: parent.width - 20
            text: rootWindow.statusMessage
            wrapMode: Text.WrapAnywhere
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            color: Services.Theme.highlight
        }
    }

    // --- OVERLAY LAYER: MENUS ---
    AudioMenu {
        id: audioMenu
        active: rootWindow.activeMenu === "audio"
        attachTo: utils.audioBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        onCloseRequested: rootWindow.activeMenu = ""
        onStatusRequested: message => rootWindow.showStatus(message)
        z: 20
    }
    
    NetworkMenu {
        id: netMenu
        active: rootWindow.activeMenu === "network"
        attachTo: utils.netBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        onCloseRequested: rootWindow.activeMenu = ""
        onStatusRequested: message => rootWindow.showStatus(message)
        z: 20
    }
    
    PowerMenu {
        id: powerMenu
        active: rootWindow.activeMenu === "power"
        attachTo: utils.powerBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        onCloseRequested: rootWindow.activeMenu = ""
        onStatusRequested: message => rootWindow.showStatus(message)
        z: 20
    }

    FocusAudioMenu {
        id: focusAudioMenu
        active: rootWindow.activeMenu === "focusAudio"
        attachTo: utils.focusBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        onCloseRequested: rootWindow.activeMenu = ""
        onStatusRequested: message => rootWindow.showStatus(message)
        z: 20
    }

    VpnMenu {
        id: vpnMenu
        active: rootWindow.activeMenu === "vpn"
        attachTo: utils.wgBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        onCloseRequested: rootWindow.activeMenu = ""
        onStatusRequested: message => rootWindow.showStatus(message)
        z: 20
    }
        }
    }
}
