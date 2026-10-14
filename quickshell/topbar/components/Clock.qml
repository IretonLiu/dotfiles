import QtQuick
import QtQuick.Layouts
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.rightMargin: 10

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent

    MouseArea {
        id: clockBtn
        property bool showDate: false
        
        implicitWidth: contentRow.implicitWidth + 16
        implicitHeight: 32
        Layout.alignment: Qt.AlignVCenter
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
        function utcOffsetLabel() {
            const offsetMinutes = -new Date().getTimezoneOffset()
            const sign = offsetMinutes >= 0 ? "+" : "-"
            const absoluteMinutes = Math.abs(offsetMinutes)
            const hours = Math.floor(absoluteMinutes / 60)
            const minutes = absoluteMinutes % 60
            return "UTC" + sign + hours + (minutes > 0 ? ":" + minutes.toString().padStart(2, "0") : "")
        }

        function updateDisplay() {
            if (showDate) {
                timeText.text = Qt.formatDateTime(new Date(), "ddd, MMM d")
                timeText.font.pixelSize = 14
                subtitleText.text = "SYS_DATE"
            } else {
                timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
                timeText.font.pixelSize = 19
                subtitleText.text = "SYS_TIME"
            }
            timezoneText.text = utcOffsetLabel()
        }
        
        onClicked: {
            showDate = !showDate
            updateDisplay()
        }

        Component.onCompleted: updateDisplay()

        // --- HIGHLIGHT ANIMATION ---
        property bool showHighlight: containsMouse
        
        AnimatedAccentFrame {
            active: clockBtn.showHighlight
            accentColor: root.accentColor
            z: 2
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 14
            
            Text {
                id: timeText
                font.family: "JetBrains Mono"
                font.bold: true
                color: root.textColor
                
                Timer {
                    interval: 10000
                    running: true
                    repeat: true
                    onTriggered: clockBtn.updateDisplay()
                }
            }

            Column {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    id: subtitleText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.accentColor
                    opacity: 0.8
                }
                
                Text {
                    id: timezoneText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: root.textColor
                    opacity: 0.5
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: root.accentColor
            opacity: parent.containsMouse ? 0.1 : 0
            radius: 4
        }
    }
}
