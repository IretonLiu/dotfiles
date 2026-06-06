import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as Services

FlowMenu {
    id: root
    verticalLabel: "PWR"
    
    onActiveChanged: {
        if (!active) {
            optReboot.confirming = false
            optShutdown.confirming = false
            optLogout.confirming = false
        }
    }
    
    ColumnLayout {
        spacing: 6
        
        component PowerOption: Item {
            id: optionRoot
            property string icon: ""
            property string label: ""
            property color color: Services.Theme.highlight
            property bool confirming: false
            
            signal clicked()
            
            Layout.preferredWidth: 150
            Layout.preferredHeight: 30

            // --- HIGHLIGHT ANIMATION ---
            property bool showHighlight: mainMouseArea.containsMouse || denyMouse.containsMouse || confirmMouse.containsMouse
            
            Rectangle {
                id: highlightFrame
                anchors.centerIn: parent
                width: parent.width + (showHighlight ? 4 : -4)
                height: parent.height + (showHighlight ? 4 : -4)
                opacity: showHighlight ? 0.3 : 0
                color: "transparent"
                border.width: 1
                border.color: optionRoot.color
                radius: 4
                
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 300 } }

                // Scanning corner accents
                Repeater {
                    model: 4
                    Rectangle {
                        width: 4; height: 4
                        color: optionRoot.color
                        opacity: highlightFrame.opacity * 2
                        
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
                color: showHighlight ? Services.Theme.surfaceLighter : "transparent"
                radius: 4
                
                // DEFAULT VIEW
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 12
                    opacity: optionRoot.confirming ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    Text {
                        text: icon
                        font.family: "JetBrains Mono"
                        font.pixelSize: 22
                        color: optionRoot.color
                    }
                    Text {
                        text: label
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: true
                        color: optionRoot.color
                    }
                }
                
                // CONFIRM VIEW
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    opacity: optionRoot.confirming ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    // Deny Button
                    MouseArea {
                        id: denyMouse
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: optionRoot.confirming
                        onClicked: optionRoot.confirming = false
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Services.Theme.danger
                            opacity: parent.containsMouse ? 0.2 : 0
                            radius: 4
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "DENY"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.bold: true
                            color: parent.containsMouse ? Services.Theme.danger : Services.Theme.muted
                        }
                    }
                    
                    // Confirm Button
                    MouseArea {
                        id: confirmMouse
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: optionRoot.confirming
                        onClicked: {
                            optionRoot.confirming = false;
                            optionRoot.clicked();
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            color: Services.Theme.success
                            opacity: parent.containsMouse ? 0.2 : 0
                            radius: 4
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "CONFIRM"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.bold: true
                            color: parent.containsMouse ? Services.Theme.success : optionRoot.color
                        }
                    }
                }
            }
            
            // MAIN CLICK AREA
            MouseArea {
                id: mainMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !optionRoot.confirming
                onClicked: optionRoot.confirming = true
            }
        }
        
        PowerOption {
            id: optReboot
            icon: "󰜉"
            label: "REBOOT_SYSTEM"
            onClicked: console.log("reboot")
        }
        
        PowerOption {
            id: optShutdown
            icon: "󰐥"
            label: "SHUTDOWN_HALT"
            color: Services.Theme.danger
            onClicked: console.log("shutdown")
        }
        
        PowerOption {
            id: optLogout
            icon: "󰍃"
            label: "LOGOUT_SESSION"
            onClicked: console.log("logout")
        }
    }
}
