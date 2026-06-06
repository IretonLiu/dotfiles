import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "components"

PanelWindow {
    id: rootWindow
    
    // --- PIPEWIRE TRACKING ---
    // PwObjectTracker ensures that the properties of Pipewire nodes (volume, mute, etc.)
    // stay synchronized and "bound" in Quickshell.
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
    
    // Fixed full height to prevent coordinate jumps during animations
    implicitHeight: screen.height 
    WlrLayershell.exclusiveZone: 40
    WlrLayershell.layer: WlrLayer.Top

    // --- CRITICAL FIX FOR GHOST LAYER ---
    // Define an input mask. When no menu is active, the window only captures 
    // input in the top 40px (the bar). When a menu is active, it captures 
    // the whole screen to handle "click away" closing.
    mask: Region {
        width: rootWindow.width
        height: rootWindow.activeMenu !== "" ? rootWindow.height : barRow.height
    }
    
    color: "transparent"

    // --- MODERN OPAQUE WHITE PALETTE ---
    readonly property color cfgSurface: "#F8FAFC" 
    readonly property color cfgAccent: "#334155"  
    readonly property color cfgMuted: "#94A3B8"
    readonly property color cfgHighlight: "#0F172A" 
    readonly property color cfgBorder: Qt.rgba(0, 0, 0, 0.08)

    // Global Close Handler
    // When enabled, it blocks the whole screen. We only enable it when a menu is active.
    MouseArea {
        anchors.fill: parent
        enabled: rootWindow.activeMenu !== ""
        onPressed: rootWindow.activeMenu = ""
        z: 0 // Below the bar and menus
    }

    property string activeMenu: ""

    // The Bar Island Row (Restored to Top)
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
            accentColor: cfgAccent
            padding: 4
            Workspaces {
                accentColor: cfgAccent
                mutedColor: cfgMuted
                bgColor: "#FFFFFF"
            }
        }

        Item { Layout.fillWidth: true }

        // --- CENTER: SYSTEM MONITOR ---
        AestheticContainer {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
            accentColor: cfgAccent
            padding: 4
            SystemMonitor {
                textColor: cfgHighlight
                accentColor: cfgAccent
                mutedColor: cfgMuted
            }
        }

        Item { Layout.fillWidth: true }

        // --- RIGHT-CENTER: UTILITIES ---
        AestheticContainer {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
            accentColor: cfgAccent
            padding: 4
            Utilities {
                id: utils
                textColor: cfgHighlight
                accentColor: cfgAccent
                mutedColor: cfgMuted
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
            accentColor: cfgAccent
            padding: 4
            Clock {
                textColor: cfgHighlight
                accentColor: cfgAccent
            }
        }
    }
    
    // --- OVERLAY LAYER: MENUS ---
    // We keep these at a higher Z so they stay above the global close handler
    AudioMenu {
        id: audioMenu
        active: rootWindow.activeMenu === "audio"
        attachTo: utils.audioBtn
        accentColor: cfgAccent
        surfaceColor: cfgSurface
        z: 20
    }
    
    NetworkMenu {
        id: netMenu
        active: rootWindow.activeMenu === "network"
        attachTo: utils.netBtn
        accentColor: cfgAccent
        surfaceColor: cfgSurface
        z: 20
    }
    
    PowerMenu {
        id: powerMenu
        active: rootWindow.activeMenu === "power"
        attachTo: utils.powerBtn
        accentColor: cfgAccent
        surfaceColor: cfgSurface
        z: 20
    }
}
