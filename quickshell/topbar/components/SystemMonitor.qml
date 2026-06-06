import QtQuick
import QtQuick.Layouts
import "../services" as Services

RowLayout {
    id: root
    spacing: 16
    Layout.leftMargin: 12
    Layout.rightMargin: 12

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    // --- DECORATIVE: TELEMETRY LABEL (Vertical) ---
    Item {
        Layout.preferredWidth: 8
        Layout.fillHeight: true
        
        Text {
            anchors.centerIn: parent
            text: "TLM"
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
            width: 1; height: parent.height - 12
            color: root.accentColor
            opacity: 0.2
        }
    }

    component MonitorItem: Column {
        property string label: ""
        property string value: ""
        property real progress: 0
        property string techCode: "0x" + Math.round(progress * 255).toString(16).toUpperCase()
        property color itemColor: root.accentColor
        
        spacing: 1
        
        Row {
            spacing: 6
            Text {
                text: label
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                font.weight: Font.Bold
                color: root.mutedColor
            }
            Text {
                text: techCode
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                color: itemColor
                opacity: 0.6
            }
        }
        
        Row {
            spacing: 6
            Text {
                text: value
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
                color: root.textColor
            }
            
            // --- SEGMENTED BAR ---
            Rectangle {
                width: 42
                height: 5
                color: Services.Theme.track
                radius: 1
                anchors.verticalCenter: parent.verticalCenter
                
                // Progress Fill
                Rectangle {
                    width: parent.width * progress
                    height: parent.height
                    color: itemColor
                    radius: 1
                    
                    // Texture: Internal segments
                    Row {
                        anchors.fill: parent
                        spacing: 3
                        clip: true
                        Repeater {
                            model: 10
                            Rectangle {
                                width: 1; height: parent.height
                                color: Services.Theme.surfaceDarker
                                opacity: 0.3
                            }
                        }
                    }
                }
                
                // End Cap Marker
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: -2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 8
                    color: itemColor
                    opacity: 0.5
                }
            }
        }
    }

    MonitorItem {
        label: "CPU_LOAD"
        value: "24.5%"
        progress: 0.245
    }

    MonitorItem {
        label: "MEM_USAGE"
        value: "4.2GB"
        progress: 0.42
    }

    MonitorItem {
        label: "BAT_LEVEL"
        value: "86.0%"
        progress: 0.86
        itemColor: progress >= 0.70 ? Services.Theme.success : (progress <= 0.20 ? Services.Theme.danger : root.accentColor)
    }
}
