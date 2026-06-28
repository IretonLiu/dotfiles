import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "services" as Services
import "components"

ShellRoot {
    Process {
        id: polkitAgent

        command: ["systemctl", "--user", "start", "hyprpolkitagent.service"]
    }
    
    // --- PIPEWIRE TRACKING ---
    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource
        ]
    }

    Component.onCompleted: {
        polkitAgent.running = true
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
    WlrLayershell.exclusiveZone: 52
    WlrLayershell.layer: WlrLayer.Top

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

    // The Bar Island Container
    property int barHeight: 48
    
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
            
            AestheticContainer {
                id: clockIsland
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                Clock {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                }
            }

            AestheticContainer {
                id: systemIsland
                anchors.left: clockIsland.right
                anchors.leftMargin: leftGroup.spacing
                anchors.verticalCenter: parent.verticalCenter
                height: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                SystemMonitor {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                }
            }

            AestheticContainer {
                id: mediaIsland
                anchors.left: systemIsland.right
                anchors.leftMargin: leftGroup.spacing
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(240, Math.max(0, leftGroup.width - x))
                height: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                visible: Services.Media.active !== null && width > 0
                clip: true
                MediaPlayer {
                    Layout.preferredWidth: Math.max(0, mediaIsland.width - mediaIsland.padding * 2)
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                }
            }
        }

        // --- CENTER: WORKSPACES ---
        AestheticContainer {
            id: workspaceIsland
            readonly property real maxCenteredWidth: Math.max(120, 2 * Math.min(parent.width / 2 - leftGroup.minimumContentWidth - 8, rightGroup.x - parent.width / 2 - 8))

            anchors.centerIn: parent
            height: rootWindow.barHeight - 2
            width: Math.min(implicitWidth, maxCenteredWidth)
            accentColor: Services.Theme.accent
            padding: 4
            clip: true
            Workspaces {
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
            
            AestheticContainer {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                Utilities {
                    id: utils
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                    onMenuToggle: (name) => {
                        if (rootWindow.activeMenu === name) rootWindow.activeMenu = ""
                        else rootWindow.activeMenu = name
                    }
                }
            }
        }
    }
    
    // --- OVERLAY LAYER: MENUS ---
    AudioMenu {
        id: audioMenu
        active: rootWindow.activeMenu === "audio"
        attachTo: utils.audioBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        z: 20
    }
    
    NetworkMenu {
        id: netMenu
        active: rootWindow.activeMenu === "network"
        attachTo: utils.netBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        z: 20
    }
    
    PowerMenu {
        id: powerMenu
        active: rootWindow.activeMenu === "power"
        attachTo: utils.powerBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        z: 20
    }

    VpnMenu {
        id: vpnMenu
        active: rootWindow.activeMenu === "vpn"
        attachTo: utils.wgBtn
        accentColor: Services.Theme.accent
        surfaceColor: Services.Theme.surface
        z: 20
    }
        }
    }
}
