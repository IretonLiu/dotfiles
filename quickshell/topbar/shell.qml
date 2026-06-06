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
        height: rootWindow.activeMenu !== "" ? rootWindow.height : barRow.height
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

    // The Bar Island Row
    RowLayout {
        id: barRow
        height: 40
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16
        z: 10 

        // --- LEFT: WORKSPACES ---
        AestheticContainer {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
            accentColor: Services.Theme.accent
            padding: 4
            Workspaces {
                accentColor: Services.Theme.accent
                mutedColor: Services.Theme.muted
                bgColor: Services.Theme.surface
            }
        }

        Item { Layout.fillWidth: true }

        // --- CENTER: SYSTEM MONITOR ---
        AestheticContainer {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
            accentColor: Services.Theme.accent
            padding: 4
            SystemMonitor {
                textColor: Services.Theme.highlight
                accentColor: Services.Theme.accent
                mutedColor: Services.Theme.muted
            }
        }

        Item { Layout.fillWidth: true }

        // --- RIGHT-CENTER: UTILITIES ---
        AestheticContainer {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
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

        // --- RIGHT: CLOCK ---
        AestheticContainer {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
            accentColor: Services.Theme.accent
            padding: 4
            Clock {
                textColor: Services.Theme.highlight
                accentColor: Services.Theme.accent
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
