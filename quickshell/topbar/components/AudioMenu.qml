import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services" as Services

FlowMenu {
    id: root
    verticalLabel: "AUD"
    
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
        spacing: 14
        
        // Header
        RowLayout {
            spacing: 12
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
            spacing: 10
            
            Item {
                id: sliderTrack
                Layout.preferredWidth: 240
                Layout.preferredHeight: 12
                
                readonly property real currentVolume: root.defaultSink?.audio?.volume ?? 0
                
                // Hover highlight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 4
                    color: root.accentColor
                    opacity: sliderMouse.containsMouse ? 0.15 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Left Boundary
                Rectangle {
                    id: leftBoundary
                    width: 2; height: 10
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accentColor
                }

                // Right Boundary
                Rectangle {
                    id: rightBoundary
                    width: 2; height: 10
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: Services.Theme.track
                }

                // Background Line
                Rectangle {
                    anchors.left: leftBoundary.right
                    anchors.right: rightBoundary.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: 2
                    color: Services.Theme.track
                }
                
                // Active Fill Container
                Item {
                    anchors.left: leftBoundary.right
                    anchors.right: rightBoundary.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    
                    // Hover Ghost Fill (Preview Indicator)
                    Rectangle {
                        width: parent.width * sliderMouse.hoverVal
                        height: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accentColor
                        opacity: sliderMouse.containsMouse && !sliderMouse.pressed ? 0.4 : 0
                        
                        // Ghost End Cap
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2; height: 10
                            color: root.accentColor
                        }
                    }

                    // Actual progress fill
                    Rectangle {
                        width: parent.width * sliderTrack.currentVolume
                        height: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accentColor
                        
                        // Technical "End Cap" (Moving Handle)
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2; height: 10
                            color: root.accentColor
                        }
                    }
                }
                
                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    anchors.margins: -10 // Larger hit area
                    hoverEnabled: true

                    // Calculate X relative to the inner track (compensating for the -10 margin)
                    property real relativeX: mouseX - 10
                    property real hoverVal: Math.max(0, Math.min(1, relativeX / sliderTrack.width))

                    onPressed: (mouse) => updateVolume(mouse)
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            updateVolume(mouse)
                        }
                    }
                    
                    function updateVolume(mouse) {
                        let val = Math.max(0, Math.min(1, (mouse.x - 10) / sliderTrack.width))
                        // Use wpctl for setting volume
                        shellCommand.run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)])
                    }
                }
            }
            
            Text {
                property int displayVol: sliderMouse.containsMouse && !sliderMouse.pressed 
                                         ? Math.round(sliderMouse.hoverVal * 100) 
                                         : Math.round((root.defaultSink?.audio?.volume ?? 0) * 100)
                text: displayVol + "%"
                font.family: "JetBrains Mono"
                font.pixelSize: 12 
                font.bold: true
                color: Services.Theme.highlight
                opacity: sliderMouse.containsMouse && !sliderMouse.pressed ? 0.7 : 1.0
                Layout.preferredWidth: 40 
            }
        }
        
        // Bottom Actions Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            // Mute Toggle
            MouseArea {
                id: muteBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: {
                    if (root.defaultSink && root.defaultSink.audio) {
                        root.defaultSink.audio.muted = !root.defaultSink.audio.muted;
                    }
                }

                // --- HIGHLIGHT ANIMATION ---
                property bool showHighlight: containsMouse
                readonly property bool isMuted: !!root.defaultSink?.audio?.muted
                readonly property color baseColor: isMuted ? Services.Theme.danger : root.accentColor
                
                Rectangle {
                    id: highlightFrame
                    anchors.centerIn: parent
                    width: parent.width + (muteBtn.showHighlight ? 4 : -4)
                    height: parent.height + (muteBtn.showHighlight ? 4 : -4)
                    opacity: muteBtn.showHighlight ? 0.3 : 0
                    color: "transparent"
                    border.width: 1
                    border.color: muteBtn.baseColor
                    radius: 4
                    
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    // Scanning corner accents
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 4; height: 4
                            color: muteBtn.baseColor
                            opacity: highlightFrame.opacity * 2
                            
                            anchors.top: index < 2 ? parent.top : undefined
                            anchors.bottom: index >= 2 ? parent.bottom : undefined
                            anchors.left: index % 2 == 0 ? parent.left : undefined
                            anchors.right: index % 2 != 0 ? parent.right : undefined
                            anchors.margins: -1
                        }
                    }
                }
                
                // --- MAIN BUTTON FRAME (Match Utilities Style) ---
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    
                    Text {
                        text: muteBtn.isMuted ? "󰝟" : "󰕾"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 24
                        color: muteBtn.baseColor
                    }
                    
                    Column {
                        spacing: -2
                        
                        Text {
                            text: muteBtn.isMuted ? "UNMUTE_SYSTEM" : "MUTE_SYSTEM"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.bold: true
                            color: Services.Theme.highlight
                        }
                        
                        Text {
                            text: "AUDIO_SINK"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.weight: Font.Bold
                            color: Services.Theme.muted
                        }
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: muteBtn.baseColor
                    opacity: parent.containsMouse ? 0.1 : 0
                    radius: 4
                }
            }
            
            // Control Panel
            MouseArea {
                id: mixerBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: {
                    shellCommand.run(["hyprctl", "dispatch", "exec", "[float] pwvucontrol"])
                    // close the menu via quickshell API or let the system handle focus
                }

                property bool showHighlight: containsMouse
                readonly property color baseColor: root.accentColor
                
                Rectangle {
                    id: mixerHighlightFrame
                    anchors.centerIn: parent
                    width: parent.width + (mixerBtn.showHighlight ? 4 : -4)
                    height: parent.height + (mixerBtn.showHighlight ? 4 : -4)
                    opacity: mixerBtn.showHighlight ? 0.3 : 0
                    color: "transparent"
                    border.width: 1
                    border.color: mixerBtn.baseColor
                    radius: 4
                    
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    Repeater {
                        model: 4
                        Rectangle {
                            width: 4; height: 4
                            color: mixerBtn.baseColor
                            opacity: mixerHighlightFrame.opacity * 2
                            
                            anchors.top: index < 2 ? parent.top : undefined
                            anchors.bottom: index >= 2 ? parent.bottom : undefined
                            anchors.left: index % 2 == 0 ? parent.left : undefined
                            anchors.right: index % 2 != 0 ? parent.right : undefined
                            anchors.margins: -1
                        }
                    }
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    
                    Text {
                        text: "󰒓" // Gear icon
                        font.family: "JetBrains Mono"
                        font.pixelSize: 24
                        color: mixerBtn.baseColor
                    }
                    
                    Column {
                        spacing: -2
                        
                        Text {
                            text: "CONTROL_PANEL"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.bold: true
                            color: Services.Theme.highlight
                        }
                        
                        Text {
                            text: "PWVUCONTROL"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.weight: Font.Bold
                            color: Services.Theme.muted
                        }
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: mixerBtn.baseColor
                    opacity: parent.containsMouse ? 0.1 : 0
                    radius: 4
                }
            }
        }
    }
}
