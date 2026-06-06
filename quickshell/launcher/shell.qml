import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services
import "components"

PanelWindow {
    id: rootWindow
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive // Steal focus for typing

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
    }

    // Logic for filtering apps
    property string queryText: ""
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: {
        if (queryText === "") return allApps;
        return allApps.filter(app => {
            return app.name.toLowerCase().includes(queryText.toLowerCase()) ||
                   (app.comment && app.comment.toLowerCase().includes(queryText.toLowerCase()));
        });
    }

    function launchApp(app) {
        if (!app) return;
        Quickshell.execDetached(app.command);
        Qt.quit();
    }

    // Centered Rofi-style Window
    Rectangle {
        id: launcherBox
        width: 700 // Widened for sidebar
        height: 500
        anchors.centerIn: parent
        color: Services.Theme.surface
        radius: 4
        border.width: 1
        border.color: Services.Theme.border

        // --- DECORATIVE SIDEBAR ---
        Rectangle {
            id: sideBar
            width: 40
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Services.Theme.accent
            radius: 2
            opacity: 0.8
            
            Text {
                anchors.centerIn: parent
                text: "APP_ORBITAL_LAUNCHER_V2"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.bold: true
                color: Services.Theme.surface
                rotation: -90
                width: 400
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Key handling moved inside the Item
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                Qt.quit();
            } else if (event.key === Qt.Key_Down) {
                resultList.moveDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                resultList.moveUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return) {
                resultList.launchCurrent();
                event.accepted = true;
            }
        }
        
        // Drop shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -4
            anchors.rightMargin: -4
            anchors.bottomMargin: -6
            anchors.topMargin: parent.radius
            color: Services.Theme.shadow
            z: -1
            radius: 4
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 56 // Offset for sidebar
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            spacing: 16
            
            // Search Input Area
            SearchField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                onTextChanged: (text) => {
                    rootWindow.queryText = text;
                    resultList.currentIndex = 0;
                }
                onAccepted: {
                    resultList.launchCurrent();
                }
            }

            // Divider with technical text
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

            // Results Area
            ResultList {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: rootWindow.filteredApps
                onAppLaunched: (app) => rootWindow.launchApp(app)
            }
        }
    }
    
    // Auto-focus the search field when the window appears
    Component.onCompleted: {
        searchInput.forceActiveFocus()
    }
}

