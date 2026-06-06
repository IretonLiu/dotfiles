import QtQuick
import QtQuick.Layouts
import Quickshell

FlowMenu {
    id: root
    
    ColumnLayout {
        spacing: 8
        Layout.margins: 8
        
        component PowerOption: MouseArea {
            property string icon: ""
            property string label: ""
            property color color: "#0F172A"
            
            Layout.preferredWidth: 160
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            
            Rectangle {
                anchors.fill: parent
                color: parent.containsMouse ? Qt.rgba(0, 0, 0, 0.05) : "transparent"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 14
                    Text {
                        text: icon
                        font.family: "JetBrains Mono"
                        font.pixelSize: 28
                        color: parent.parent.parent.color
                    }
                    Text {
                        text: label
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: true
                        color: parent.parent.parent.color
                    }
                }
            }
        }
        
        PowerOption {
            icon: "󰜉"
            label: "REBOOT_SYSTEM"
            onClicked: console.log("reboot")
        }
        
        PowerOption {
            icon: "󰐥"
            label: "SHUTDOWN_HALT"
            color: "#EF4444"
            onClicked: console.log("shutdown")
        }
        
        PowerOption {
            icon: "󰍃"
            label: "LOGOUT_SESSION"
            onClicked: console.log("logout")
        }
    }
}
