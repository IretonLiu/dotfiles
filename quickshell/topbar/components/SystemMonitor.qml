import QtQuick
import QtQuick.Layouts
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    component MonitorItem: Column {
        property string label: ""
        property string value: ""
        property real progress: 0
        
        spacing: 1
        
        Text {
            text: label
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            font.weight: Font.Bold
            color: root.mutedColor
        }
        
        Row {
            spacing: 5
            Text {
                text: value
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.bold: true
                color: root.textColor
            }
            
            Rectangle {
                width: 36
                height: 4
                radius: 1
                color: Services.Theme.track
                anchors.verticalCenter: parent.verticalCenter
                
                Rectangle {
                    width: parent.width * progress
                    height: parent.height
                    radius: 1
                    color: root.accentColor
                    opacity: 1.0 // Full opacity for visibility on dark
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
}
