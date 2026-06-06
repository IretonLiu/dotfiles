import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services" as Services

FlowMenu {
    id: root
    
    // Helper to run shell commands
    Process {
        id: shellCommand
        function run(args) {
            command = args
            running = true
        }
    }

    // Reference the default audio sink to keep UI reactive
    readonly property var defaultSink: Pipewire.defaultAudioSink

    ColumnLayout {
        spacing: 16
        Layout.margins: 10
        
        // Header
        RowLayout {
            spacing: 12
            Text {
                text: "󰕾"
                font.family: "JetBrains Mono"
                font.pixelSize: 28 
                color: root.accentColor
            }
            Column {
                spacing: -2
                Text {
                    text: "AUDIO_CONTROL"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11 
                    font.bold: true
                    color: Services.Theme.highlight
                }
                Text {
                    text: root.defaultSink?.description ?? "Unknown Device"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9 
                    color: Services.Theme.muted
                    Layout.preferredWidth: 210
                    elide: Text.ElideRight
                }
            }
        }
        
        // Slider
        RowLayout {
            spacing: 12
            
            Rectangle {
                id: sliderTrack
                Layout.preferredWidth: 260
                Layout.preferredHeight: 6
                color: Services.Theme.track
                radius: 3
                
                readonly property real currentVolume: root.defaultSink?.audio?.volume ?? 0
                
                Rectangle {
                    width: parent.width * parent.currentVolume
                    height: parent.height
                    color: root.accentColor
                    radius: 3
                    
                    // Technical "End Cap"
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4; height: 10
                        color: root.accentColor
                        radius: 1
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10 // Larger hit area
                    onPressed: (mouse) => updateVolume(mouse)
                    onPositionChanged: (mouse) => updateVolume(mouse)
                    
                    function updateVolume(mouse) {
                        let val = Math.max(0, Math.min(1, mouse.x / sliderTrack.width))
                        // Use wpctl for setting volume
                        shellCommand.run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)])
                    }
                }
            }
            
            Text {
                text: Math.round((root.defaultSink?.audio?.volume ?? 0) * 100) + "%"
                font.family: "JetBrains Mono"
                font.pixelSize: 13 
                font.bold: true
                color: Services.Theme.highlight
                Layout.preferredWidth: 45 
            }
        }
        
        // Mute Toggle
        MouseArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                // Use wpctl for toggling mute
                shellCommand.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
            }
            
            Rectangle {
                anchors.fill: parent
                color: (root.defaultSink?.audio?.muted) ? Qt.rgba(239, 68, 68, 0.15) : Services.Theme.track
                radius: 4
                border.width: 1
                border.color: (root.defaultSink?.audio?.muted) ? Services.Theme.danger : "transparent"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        text: (root.defaultSink?.audio?.muted) ? "󰝟" : "󰕾"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 24 
                        color: (root.defaultSink?.audio?.muted) ? Services.Theme.danger : root.accentColor
                    }
                    Text {
                        text: (root.defaultSink?.audio?.muted) ? "UNMUTE_SYSTEM" : "MUTE_SYSTEM"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11 
                        font.bold: true
                        color: (root.defaultSink?.audio?.muted) ? Services.Theme.danger : Services.Theme.highlight
                    }
                }
            }
        }
    }
}
