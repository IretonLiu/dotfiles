import QtQuick
import QtQuick.Layouts
import "../services" as Services

RowLayout {
    id: root
    spacing: 14
    Layout.leftMargin: 10
    Layout.rightMargin: 10

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent

    // --- DECORATIVE: CLOCK LABEL (Vertical) ---
    Item {
        Layout.preferredWidth: 8
        Layout.fillHeight: true
        
        Text {
            anchors.centerIn: parent
            text: "CLK"
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
            width: 1; height: parent.height - 8
            color: root.accentColor
            opacity: 0.2
        }
    }

    MouseArea {
        id: clockBtn
        property bool showDate: false
        
        implicitWidth: contentRow.implicitWidth + 16
        implicitHeight: 32
        Layout.alignment: Qt.AlignVCenter
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
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
        }
        
        onClicked: {
            showDate = !showDate
            updateDisplay()
        }

        Component.onCompleted: updateDisplay()

        // --- HIGHLIGHT ANIMATION ---
        property bool showHighlight: containsMouse
        
        Rectangle {
            id: highlightFrame
            anchors.centerIn: parent
            width: parent.width + (clockBtn.showHighlight ? 4 : -4)
            height: parent.height + (clockBtn.showHighlight ? 4 : -4)
            opacity: clockBtn.showHighlight ? 0.3 : 0
            color: "transparent"
            border.width: 1
            border.color: root.accentColor
            radius: 4
            
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            // Scanning corner accents
            Repeater {
                model: 4
                Rectangle {
                    width: 4; height: 4
                    color: root.accentColor
                    opacity: highlightFrame.opacity * 2
                    
                    anchors.top: index < 2 ? parent.top : undefined
                    anchors.bottom: index >= 2 ? parent.bottom : undefined
                    anchors.left: index % 2 == 0 ? parent.left : undefined
                    anchors.right: index % 2 != 0 ? parent.right : undefined
                    anchors.margins: -1
                }
            }
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
                    interval: 1000
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
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: root.accentColor
                    opacity: 0.8
                }
                
                Text {
                    text: "UTC+2"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
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
