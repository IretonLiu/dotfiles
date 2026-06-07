import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as Services

FlowMenu {
    id: root
    verticalLabel: "VPN"

    ColumnLayout {
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
                spacing: -2

                Text {
                    text: "WIREGUARD_VPN"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: Services.Theme.highlight
                }

                Text {
                    text: Services.Vpn.busy ? "SWITCHING_CONNECTION..." : (Services.Vpn.connected ? "Active: " + Services.Vpn.activeInterface : "Disconnected")
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: Services.Theme.muted
                    width: 120
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            MouseArea {
                id: reconnectButton
                visible: !Services.Vpn.connected && Services.Vpn.lastConnectedName.length > 0
                width: visible ? 72 : 0
                height: 26
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !Services.Vpn.busy
                onClicked: Services.Vpn.connectLastUsed()

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Services.Theme.success
                    opacity: reconnectButton.containsMouse ? 0.14 : 0.06
                }

                Text {
                    anchors.centerIn: parent
                    text: "RELINK"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: Services.Theme.highlight
                }
            }

            MouseArea {
                id: refreshButton
                width: 26
                height: 26
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !Services.Vpn.busy
                onClicked: Services.Vpn.refresh()

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Services.Theme.accent
                    opacity: refreshButton.containsMouse ? 0.14 : 0.06
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: Services.Theme.highlight
                }
            }
        }

        Text {
            visible: Services.Vpn.lastError.length > 0
            text: Services.Vpn.lastError
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.danger
            wrapMode: Text.WrapAnywhere
            Layout.preferredWidth: 240
        }

        Text {
            visible: Services.Vpn.authIssue
            text: "AUTH_HINT: ensure a polkit agent is running and approve the pkexec prompt."
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.highlight
            wrapMode: Text.WrapAnywhere
            Layout.preferredWidth: 240
        }

        Text {
            visible: Services.Vpn.lastError.length === 0 && Services.Vpn.lastMessage.length > 0
            text: Services.Vpn.lastMessage
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.muted
            wrapMode: Text.WrapAnywhere
            Layout.preferredWidth: 240
        }

        Column {
            spacing: 4
            Layout.fillWidth: true

            Repeater {
                model: Services.Vpn.availableConfigs

                delegate: MouseArea {
                    id: configItem
                    width: 240
                    height: 38
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !Services.Vpn.busy

                    readonly property var config: modelData
                    readonly property bool isActive: Services.Vpn.activeInterface === config.name
                    readonly property bool isUser: config.path.indexOf("/etc/wireguard/") !== 0
                    readonly property color baseColor: configItem.isActive ? Services.Theme.success : root.accentColor
                    property bool showHighlight: containsMouse

                    onClicked: {
                        if (configItem.isActive)
                            Services.Vpn.disconnect(config.name)
                        else
                            Services.Vpn.connect(config)
                    }

                    Rectangle {
                        id: configHighlightFrame
                        anchors.centerIn: parent
                        width: parent.width + (configItem.showHighlight ? 4 : -4)
                        height: parent.height + (configItem.showHighlight ? 4 : -4)
                        opacity: configItem.showHighlight ? 0.3 : 0
                        color: "transparent"
                        border.width: 1
                        border.color: configItem.baseColor
                        radius: 4

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        Repeater {
                            model: 4
                            Rectangle {
                                width: 4
                                height: 4
                                color: configItem.baseColor
                                opacity: configHighlightFrame.opacity * 2
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
                        color: configItem.baseColor
                        opacity: configItem.containsMouse ? 0.1 : (configItem.isActive ? 0.08 : 0)
                        radius: 4
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: configItem.isActive ? "󰖂" : "󰖃"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            color: configItem.isActive ? Services.Theme.success : Services.Theme.muted
                        }

                        Column {
                            spacing: -2

                            Text {
                                text: configItem.config.name.toUpperCase()
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                font.bold: true
                                color: Services.Theme.highlight
                            }

                            Text {
                                text: configItem.isActive ? "CLICK_TO_DISCONNECT" : (configItem.config.name === Services.Vpn.lastConnectedName ? "LAST_USED" : (configItem.isUser ? "USER_CONFIG" : "SYSTEM_CONFIG"))
                                font.family: "JetBrains Mono"
                                font.pixelSize: 7
                                color: Services.Theme.muted
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 6

                            Text {
                                text: configItem.isActive ? "󰖂" : "󰌾"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 16
                                color: configItem.baseColor
                            }

                            Column {
                                spacing: -2

                                Text {
                                    text: configItem.isActive ? "DISCONNECT" : "CONNECT"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Services.Theme.highlight
                                }

                                Text {
                                    text: configItem.isActive ? "ACTIVE" : "WIREGUARD"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 6
                                    font.weight: Font.Bold
                                    color: Services.Theme.muted
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: Services.Vpn.availableConfigs.length === 0
                text: "NO_CONFIGS_FOUND_IN_/ETC_OR_$HOME/.CONFIG"
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                color: Services.Theme.danger
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 2
            }
        }

        Text {
            text: Services.Vpn.busy ? "WAITING_FOR_PKEXEC / WG-QUICK" : "SCANNING: /ETC/WIREGUARD & $HOME/.CONFIG/WIREGUARD"
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.muted
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 2
        }
    }
}
