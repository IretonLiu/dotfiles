import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

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
                font.pixelSize: 28 // 14 * 2
                color: root.accentColor
            }
            Column {
                spacing: -2
                Text {
                    text: "AUDIO_CONTROL"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11 // 10 + 1
                    font.bold: true
                    color: "#0F172A"
                }
                Text {
                    text: root.defaultSink?.description ?? "Unknown Device"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9 // 8 + 1
                    color: "#94A3B8"
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
                color: Qt.rgba(0, 0, 0, 0.05)
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
                font.pixelSize: 13 // 12 + 1
                font.bold: true
                color: "#0F172A"
                Layout.preferredWidth: 45 // Increased to fit 100%
            }
        }
        
        // Mute Toggle
        MouseArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 // Increased height for larger content
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                // Use wpctl for toggling mute
                shellCommand.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
            }
            
            Rectangle {
                anchors.fill: parent
                color: (root.defaultSink?.audio?.muted) ? Qt.rgba(239, 68, 68, 0.1) : Qt.rgba(0, 0, 0, 0.03)
                radius: 4
                border.width: 1
                border.color: (root.defaultSink?.audio?.muted) ? "#EF4444" : "transparent"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        text: (root.defaultSink?.audio?.muted) ? "󰝟" : "󰕾"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 24 // 12 * 2
                        color: (root.defaultSink?.audio?.muted) ? "#EF4444" : root.accentColor
                    }
                    Text {
                        text: (root.defaultSink?.audio?.muted) ? "UNMUTE_SYSTEM" : "MUTE_SYSTEM"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11 // 10 + 1
                        font.bold: true
                        color: (root.defaultSink?.audio?.muted) ? "#EF4444" : "#0F172A"
                    }
                }
            }
        }
    }
}
