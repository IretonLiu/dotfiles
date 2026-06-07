import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "services" as Services
import "components"

PanelWindow {
    id: rootWindow

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-launcher"
    readonly property string visibleFile: rootWindow.stateDir + "/visible"

    property bool launcherVisible: false
    property real animationProgress: launcherVisible ? 1.0 : 0.0
    property string queryText: ""

    Behavior on animationProgress {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutExpo
        }
    }
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: {
        if (queryText === "")
            return allApps;
        return allApps.filter(app => app.name.toLowerCase().includes(queryText.toLowerCase()) || (app.comment && app.comment.toLowerCase().includes(queryText.toLowerCase())));
    }

    function setVisibleState(visible) {
        launcherVisible = visible;

        if (visible) {
            queryText = "";
            Qt.callLater(() => {
                searchInput.clear();
                resultList.currentIndex = -1;
                focusDelay.restart();
            });
        }
    }

    function hideLauncher() {
        visibilityWriter.run("false");
    }

    function launchApp(app) {
        if (!app)
            return;
        Quickshell.execDetached(app.command);
        hideLauncher();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: launcherVisible || animationProgress > 0.01

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        enabled: rootWindow.animationProgress > 0.01
        onClicked: rootWindow.hideLauncher()
    }

    Rectangle {
        id: launcherBox
        readonly property real targetWidth: 700
        readonly property real targetHeight: 500

        width: targetWidth * rootWindow.animationProgress
        height: targetHeight * rootWindow.animationProgress
        anchors.centerIn: parent
        color: Services.Theme.surface
        radius: 4
        border.width: 1
        border.color: Services.Theme.border
        clip: true
        opacity: Math.min(1.0, rootWindow.animationProgress * 5)

        Rectangle {
            id: sideBar
            width: 40
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Services.Theme.accent
            radius: 2
            opacity: 0.8 * rootWindow.animationProgress

            GlitchText {
                anchors.centerIn: parent
                textData: "APP_ORBITAL_LAUNCHER_V2"
                periodicInterval: 12000 + Math.random() * 5000
                totalTicks: 16
                glitchInterval: 80
                font.pixelSize: 10
                font.bold: true
                color: Services.Theme.surface
                rotation: -90
                width: 400
                horizontalAlignment: Text.AlignHCenter
            }
        }

        focus: rootWindow.launcherVisible
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                rootWindow.hideLauncher();
            } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) {
                resultList.moveDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) {
                resultList.moveUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return) {
                resultList.launchCurrent();
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: -10
            anchors.bottomMargin: -15
            anchors.topMargin: 10
            color: Services.Theme.shadow
            opacity: rootWindow.animationProgress
            z: -1
            radius: 4
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 56
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            spacing: 16
            opacity: Math.max(0, rootWindow.animationProgress * 4 - 3)

            SearchField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                onTextChanged: text => {
                    rootWindow.queryText = text;
                    resultList.currentIndex = 0;
                }
                onAccepted: resultList.launchCurrent()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Services.Theme.accent
                    opacity: 0.3
                }

                Text {
                    text: "RESULT_POOL_INDEX"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: Services.Theme.accent
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 1
                    color: Services.Theme.accent
                    opacity: 0.3
                }
            }

            ResultList {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: rootWindow.filteredApps
                onAppLaunched: app => rootWindow.launchApp(app)
            }
        }
    }

    Repeater {
        model: 4

        delegate: Rectangle {
            width: 3
            height: 3
            color: Services.Theme.accent
            opacity: 0.9
            visible: rootWindow.animationProgress > 0.01
            z: 100

            readonly property real startX: rootWindow.width / 2 - width / 2
            readonly property real startY: rootWindow.height / 2 - height / 2
            readonly property real targetX: launcherBox.x + (index % 2 === 0 ? -1 : launcherBox.targetWidth - width + 1)
            readonly property real targetY: launcherBox.y + (index < 2 ? -1 : launcherBox.targetHeight - height + 1)

            x: startX + (targetX - startX) * rootWindow.animationProgress
            y: startY + (targetY - startY) * rootWindow.animationProgress
        }
    }

    FileView {
        id: visibleState
        path: rootWindow.visibleFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = (text() || "").trim();
            rootWindow.setVisibleState(value === "true");
        }
    }

    Timer {
        id: focusDelay
        interval: 380
        onTriggered: {
            if (!rootWindow.launcherVisible)
                return;
            resultList.currentIndex = 0;
            searchInput.forceActiveFocus();
        }
    }

    Process {
        id: visibilityWriter

        function run(value) {
            command = ["sh", "-lc", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "sh", rootWindow.stateDir, value, rootWindow.visibleFile];
            running = true;
        }
    }
}
