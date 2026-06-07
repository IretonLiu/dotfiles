import QtQuick
import QtQuick.Layouts
import "../services" as Services

RowLayout {
    id: root
    spacing: 18
    Layout.leftMargin: 14
    Layout.rightMargin: 14

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    // --- DECORATIVE: TELEMETRY LABEL ---
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
        property color itemColor: root.accentColor
        
        spacing: 1
        
        Row {
            spacing: 6
            Text {
                text: label
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                font.weight: Font.Bold
                color: root.mutedColor
            }
        }
        
        Row {
            spacing: 6
            Text {
                text: value
                font.family: "JetBrains Mono"
                font.pixelSize: 14
                font.bold: true
                color: root.textColor
            }
            
            // --- NEW STYLE: GEOMETRIC MINIMALIST BAR ---
            Item {
                width: 46
                height: 4
                anchors.verticalCenter: parent.verticalCenter
                
                // Track Background
                Rectangle {
                    anchors.fill: parent
                    color: Services.Theme.track
                    opacity: 0.3
                    radius: 1
                }
                
                // Progress Fill (Solid & Clean)
                Rectangle {
                    width: parent.width * progress
                    height: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: itemColor
                    radius: 1
                }
                
                // Start Marker
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2; height: 6
                    color: itemColor
                }

                // End Marker (Always visible at the end of the track)
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 6
                    color: root.mutedColor
                    opacity: 0.4
                }
            }
        }
    }

    MonitorItem {
        label: "CPU"
        value: Math.round(Services.SysUsage.cpuPerc * 100) + "%"
        progress: Services.SysUsage.cpuPerc
    }

    MonitorItem {
        label: "MEM"
        value: Services.SysUsage.formatKib(Services.SysUsage.memUsed)
        progress: Services.SysUsage.memPerc
    }

    MonitorItem {
        label: "BAT"
        value: Services.SysUsage.batValue
        progress: Services.SysUsage.batPerc
        itemColor: progress >= 0.70 ? Services.Theme.success : (progress <= 0.20 ? Services.Theme.danger : root.accentColor)
    }

    MonitorItem {
        label: "BRI"
        value: Math.round(Services.SysUsage.brightnessPerc * 100) + "%"
        progress: Services.SysUsage.brightnessPerc
    }
}
