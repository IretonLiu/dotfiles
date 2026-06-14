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
        id: monitorItem

        property string label: ""
        property string value: ""
        property real progress: 0
        property color itemColor: root.accentColor
        property bool waveActive: false
        property real barWidth: 46
        
        spacing: 1

        Behavior on barWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        
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
        
        RowLayout {
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
                id: progressBar
                Layout.preferredWidth: monitorItem.barWidth
                Layout.minimumWidth: monitorItem.barWidth
                height: 8
                Layout.alignment: Qt.AlignVCenter
                clip: true
                
                // Track Background
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    color: Services.Theme.track
                    opacity: 0.3
                    radius: 1
                }
                
                // Progress Fill / charging heartbeat pulse
                Item {
                    id: filledBar
                    width: parent.width * progress
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Rectangle {
                        id: progressFill
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: monitorItem.waveActive ? 3 : 2
                        color: itemColor
                        opacity: monitorItem.waveActive ? 0.55 : 1
                        radius: 1

                        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Rectangle {
                        id: heartbeatPulse
                        visible: monitorItem.waveActive && filledBar.width > 0
                        x: 0
                        y: (filledBar.height - height) / 2
                        width: Math.min(10, Math.max(2, filledBar.width * 0.35))
                        height: 2
                        radius: 1
                        color: monitorItem.itemColor
                        opacity: 0

                        SequentialAnimation {
                            running: heartbeatPulse.visible
                            loops: Animation.Infinite

                            ParallelAnimation {
                                NumberAnimation {
                                    target: heartbeatPulse
                                    property: "x"
                                    from: 0
                                    to: Math.max(0, filledBar.width - heartbeatPulse.width)
                                    duration: 680
                                    easing.type: Easing.OutCubic
                                }
                                SequentialAnimation {
                                    NumberAnimation { target: heartbeatPulse; property: "opacity"; from: 0; to: 1; duration: 50 }
                                    NumberAnimation { target: heartbeatPulse; property: "height"; from: 2; to: 8; duration: 80; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: heartbeatPulse; property: "height"; from: 8; to: 2; duration: 120; easing.type: Easing.InQuad }
                                    NumberAnimation { target: heartbeatPulse; property: "height"; from: 2; to: 5; duration: 70; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: heartbeatPulse; property: "height"; from: 5; to: 2; duration: 100; easing.type: Easing.InQuad }
                                    NumberAnimation { target: heartbeatPulse; property: "opacity"; from: 1; to: 0.85; duration: 260 }
                                }
                            }

                            PauseAnimation { duration: 180 }
                            NumberAnimation { target: heartbeatPulse; property: "opacity"; to: 0; duration: 120 }
                            PropertyAction { target: heartbeatPulse; property: "x"; value: 0 }
                            PropertyAction { target: heartbeatPulse; property: "height"; value: 2 }
                            PauseAnimation { duration: 220 }
                        }
                    }
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

    Item {
        id: resourceGroup

        property bool expanded: false
        readonly property int collapsedWidth: 54
        readonly property int expandedWidth: resourcesRow.implicitWidth
        property bool showHighlight: resourceMouse.containsMouse || expanded

        Layout.preferredWidth: expanded ? expandedWidth : collapsedWidth
        Layout.preferredHeight: 32
        Layout.alignment: Qt.AlignVCenter

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        // Same hover treatment as UtilityButton in Utilities.qml.
        Rectangle {
            id: resourceHighlightFrame
            anchors.centerIn: parent
            width: parent.width + (resourceGroup.showHighlight ? 4 : -4)
            height: parent.height + (resourceGroup.showHighlight ? 4 : -4)
            opacity: resourceGroup.showHighlight ? 0.3 : 0
            color: "transparent"
            border.width: 1
            border.color: root.accentColor
            radius: 4

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Repeater {
                model: 4
                Rectangle {
                    width: 4; height: 4
                    color: root.accentColor
                    opacity: resourceHighlightFrame.opacity * 2

                    anchors.top: index < 2 ? parent.top : undefined
                    anchors.bottom: index >= 2 ? parent.bottom : undefined
                    anchors.left: index % 2 == 0 ? parent.left : undefined
                    anchors.right: index % 2 != 0 ? parent.right : undefined
                    anchors.margins: -1
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Services.Theme.accent
            opacity: resourceMouse.containsMouse ? 0.1 : 0
            radius: 4
        }

        Item {
            anchors.fill: parent
            clip: true

            RowLayout {
                id: collapsedResource
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: resourceGroup.collapsedWidth - 16
                spacing: 6
                opacity: resourceGroup.expanded ? 0 : 1
                visible: opacity > 0

                Text {
                    text: "RES"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.mutedColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: [Services.SysUsage.cpuPerc, Services.SysUsage.memPerc, Services.SysUsage.brightnessPerc]

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: root.accentColor
                            opacity: 0.25 + modelData * 0.65
                        }
                    }
                }

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            RowLayout {
                id: resourcesRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                opacity: resourceGroup.expanded ? 1 : 0
                visible: opacity > 0

                MonitorItem {
                    label: "CPU"
                    value: Math.round(Services.SysUsage.cpuPerc * 100) + "%"
                    progress: Services.SysUsage.cpuPerc
                    barWidth: 38
                }

                MonitorItem {
                    label: "MEM"
                    value: Services.SysUsage.formatKib(Services.SysUsage.memUsed)
                    progress: Services.SysUsage.memPerc
                    barWidth: 38
                }

                MonitorItem {
                    label: "BRI"
                    value: Math.round(Services.SysUsage.brightnessPerc * 100) + "%"
                    progress: Services.SysUsage.brightnessPerc
                    barWidth: 38
                }

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: resourceMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: resourceGroup.expanded = !resourceGroup.expanded
        }
    }

    MonitorItem {
        label: "BAT"
        value: Services.SysUsage.batValue
        progress: Services.SysUsage.batPerc
        waveActive: Services.SysUsage.chargerPlugged
        itemColor: Services.SysUsage.chargerPlugged ? Services.Theme.success : (progress >= 0.70 ? Services.Theme.success : (progress <= 0.20 ? Services.Theme.danger : root.accentColor))
    }
}
