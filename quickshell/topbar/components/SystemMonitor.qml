import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 14
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property color textColor: "#0F172A"
    property color accentColor: "#334155"
    property color mutedColor: "#94A3B8"

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
                color: root.accentColor
                opacity: 0.1
                anchors.verticalCenter: parent.verticalCenter
                
                Rectangle {
                    width: parent.width * progress
                    height: parent.height
                    radius: 1
                    color: root.accentColor
                    opacity: 0.9
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
