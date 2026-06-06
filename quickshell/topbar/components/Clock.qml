import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 12
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property color textColor: "#0F172A"
    property color accentColor: "#334155"

    Text {
        id: timeText
        text: Qt.formatDateTime(new Date(), "HH:mm")
        font.family: "JetBrains Mono"
        font.pixelSize: 17
        font.bold: true
        color: root.textColor
        
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
    }

    Column {
        spacing: 0
        Layout.alignment: Qt.AlignVCenter
        
        Text {
            text: "SYS_TIME"
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            font.weight: Font.Bold
            color: root.accentColor
            opacity: 0.8
        }
        
        Text {
            text: "UTC+2"
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: root.textColor
            opacity: 0.5
        }
    }
}
