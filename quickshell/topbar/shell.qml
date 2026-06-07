import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "services" as Services
import "components"

PanelWindow {
    id: rootWindow
    
    // --- PIPEWIRE TRACKING ---
    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource
        ]
    }

    anchors {
        top: true
        left: true
        right: true
    }
    
    implicitHeight: screen.height 
    WlrLayershell.exclusiveZone: 40
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
    property int barHeight: 40
    
    Item {
        id: barContainer
        height: rootWindow.barHeight
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 1
        z: 10 

        // --- LEFT: SYSTEM MONITOR & MEDIA ---
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: 8
            
            AestheticContainer {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                SystemMonitor {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                }
            }

            AestheticContainer {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                visible: Services.Media.active !== null
                MediaPlayer {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
                    mutedColor: Services.Theme.muted
                }
            }
        }

        // --- CENTER: WORKSPACES ---
        AestheticContainer {
            anchors.centerIn: parent
            height: rootWindow.barHeight - 2
            accentColor: Services.Theme.accent
            padding: 4
            Workspaces {
                accentColor: Services.Theme.accent
                mutedColor: Services.Theme.muted
                bgColor: Services.Theme.surface
            }
        }

        // --- RIGHT: UTILITIES & CLOCK ---
        RowLayout {
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

            AestheticContainer {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: rootWindow.barHeight - 2
                accentColor: Services.Theme.accent
                padding: 4
                Clock {
                    textColor: Services.Theme.highlight
                    accentColor: Services.Theme.accent
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
}
