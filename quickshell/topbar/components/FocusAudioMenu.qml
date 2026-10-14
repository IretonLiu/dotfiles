import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services" as Services

FlowMenu {
    id: root
    verticalLabel: "DND"

    property bool showingCandidates: false

    Process {
        id: shellCommand
        property string commandLabel: ""

        function run(args, label) {
            commandLabel = label || args[0]
            command = args
            running = true
        }

        onExited: code => {
            if (code !== 0)
                root.statusRequested(commandLabel + " failed (exit " + code + ")")
        }
    }

    function toggleCandidates() {
        showingCandidates = !showingCandidates;
        if (showingCandidates)
            Services.FocusAudio.refreshAvailableApps();
    }

    onActiveChanged: {
        if (active)
            Services.FocusAudio.refreshAvailableApps();
        else
            showingCandidates = false;
    }

    component ActionButton: MouseArea {
        id: button
        property string icon: ""
        property string label: ""
        property color baseColor: root.accentColor
        signal activated()

        Layout.fillWidth: true
        Layout.preferredHeight: 30
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        activeFocusOnTab: true
        onPressed: forceActiveFocus()
        onClicked: activated()
        Keys.onReturnPressed: event => { event.accepted = true; activated(); }
        Keys.onEnterPressed: event => { event.accepted = true; activated(); }
        Keys.onSpacePressed: event => { event.accepted = true; activated(); }

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: button.baseColor
            opacity: button.containsMouse ? 0.16 : 0.05
            border.width: 1
            border.color: button.baseColor
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: button.icon
                font.family: "JetBrains Mono"
                font.pixelSize: 15
                color: button.baseColor
            }
            Text {
                text: button.label
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                font.bold: true
                color: button.baseColor
            }
        }
    }

    ColumnLayout {
        Layout.preferredWidth: 290
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -2

                Text {
                    text: "FOCUS_AUDIO"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.bold: true
                    color: Services.Theme.highlight
                }
                Text {
                    text: Services.Dunst.paused ? "DND_ACTIVE · SELECTED APPS MUTED" : "DND_OFF · POLICY STANDBY"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: Services.Dunst.paused ? Services.Theme.warning : Services.Theme.muted
                }
            }

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: Services.Dunst.paused ? Services.Theme.warning : Services.Theme.muted
            }
        }

        ActionButton {
            icon: Services.Dunst.paused ? "󰪑" : "󰂚"
            label: Services.Dunst.paused ? "DISABLE_FOCUS_MODE" : "ENABLE_FOCUS_MODE"
            baseColor: Services.Dunst.paused ? Services.Theme.warning : root.accentColor
            onActivated: Services.Dunst.toggle()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Services.Theme.border
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "MUTE_WHILE_DND"
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                font.bold: true
                color: root.accentColor
            }
            Text {
                text: Services.FocusAudio.selectedCount + " APP" + (Services.FocusAudio.selectedCount === 1 ? "" : "S")
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                color: Services.Theme.muted
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Services.FocusAudio.selectedCount === 0
            text: "NO APPS SELECTED · ADD ONE BELOW"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: Services.Theme.muted
            horizontalAlignment: Text.AlignHCenter
            topPadding: 6
            bottomPadding: 6
        }

        Repeater {
            model: Services.FocusAudio.selectedApps

            delegate: Item {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Services.Theme.surfaceLighter
                    border.width: 1
                    border.color: Services.Theme.border
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - removeButton.width - 24
                    spacing: -1

                    Text {
                        width: parent.width
                        text: modelData.label.toUpperCase()
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: true
                        color: Services.Theme.highlight
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: modelData.binaries.length > 0 ? "PROCESS: " + modelData.binaries.join(", ") : "APP: " + modelData.applicationNames.join(", ")
                        font.family: "JetBrains Mono"
                        font.pixelSize: 7
                        color: Services.Theme.muted
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: removeButton
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    height: parent.height - 8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    activeFocusOnTab: true
                    onPressed: forceActiveFocus()
                    onClicked: Services.FocusAudio.removeApp(modelData.id)
                    Keys.onReturnPressed: event => { event.accepted = true; Services.FocusAudio.removeApp(modelData.id); }
                    Keys.onEnterPressed: event => { event.accepted = true; Services.FocusAudio.removeApp(modelData.id); }
                    Keys.onSpacePressed: event => { event.accepted = true; Services.FocusAudio.removeApp(modelData.id); }

                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: Services.Theme.danger
                        opacity: removeButton.containsMouse ? 0.18 : 0
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "REMOVE"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 8
                        font.bold: true
                        color: removeButton.containsMouse ? Services.Theme.danger : Services.Theme.muted
                    }
                }
            }
        }

        ActionButton {
            icon: showingCandidates ? "󰅖" : "󰐕"
            label: showingCandidates ? "HIDE_AVAILABLE_APPS" : "ADD_APPLICATION"
            onActivated: root.toggleCandidates()
        }

        Text {
            Layout.fillWidth: true
            visible: showingCandidates && Services.FocusAudio.loadingApps
            text: "DISCOVERING_PIPEWIRE_CLIENTS..."
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.muted
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            visible: showingCandidates && !Services.FocusAudio.loadingApps && Services.FocusAudio.availableApps.length === 0
            text: "OPEN AN APP, THEN REFRESH THIS LIST"
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.muted
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: showingCandidates ? Services.FocusAudio.availableApps : []

            delegate: MouseArea {
                id: candidateRow
                required property var modelData
                readonly property bool alreadySelected: Services.FocusAudio.isSelected(modelData.id)
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                enabled: !alreadySelected
                hoverEnabled: true
                cursorShape: alreadySelected ? Qt.ArrowCursor : Qt.PointingHandCursor
                activeFocusOnTab: true
                onPressed: forceActiveFocus()
                onClicked: Services.FocusAudio.addApp(modelData)
                Keys.onReturnPressed: event => { event.accepted = true; Services.FocusAudio.addApp(modelData); }
                Keys.onEnterPressed: event => { event.accepted = true; Services.FocusAudio.addApp(modelData); }
                Keys.onSpacePressed: event => { event.accepted = true; Services.FocusAudio.addApp(modelData); }

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: candidateRow.containsMouse && !candidateRow.alreadySelected ? root.accentColor : Services.Theme.surfaceLighter
                    opacity: candidateRow.containsMouse && !candidateRow.alreadySelected ? 0.15 : 1
                    border.width: 1
                    border.color: Services.Theme.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: candidateRow.alreadySelected ? "󰄬" : "󰐕"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        color: candidateRow.alreadySelected ? Services.Theme.success : root.accentColor
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.label.toUpperCase()
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                        color: candidateRow.alreadySelected ? Services.Theme.muted : Services.Theme.highlight
                        elide: Text.ElideRight
                    }
                    Text {
                        text: candidateRow.alreadySelected ? "ADDED" : "ADD"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 8
                        color: candidateRow.alreadySelected ? Services.Theme.success : root.accentColor
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Services.FocusAudio.lastError !== ""
            text: Services.FocusAudio.lastError
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: Services.Theme.danger
            wrapMode: Text.WrapAnywhere
        }

        ActionButton {
            icon: "󰒓"
            label: "OPEN_PWVUCONTROL"
            onActivated: {
                shellCommand.run(["hyprctl", "dispatch", "exec", "[float] pwvucontrol"], "pwvucontrol");
                root.closeRequested();
            }
        }
    }
}
