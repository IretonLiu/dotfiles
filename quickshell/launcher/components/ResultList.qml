import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../services" as Services

Item {
    id: root
    property alias model: listView.model
    property alias currentIndex: listView.currentIndex
    
    signal appLaunched(var appEntry)

    function moveUp() {
        if (listView.currentIndex > 0) listView.currentIndex--
    }

    function moveDown() {
        if (listView.currentIndex < listView.count - 1) listView.currentIndex++
    }

    function launchCurrent() {
        if (listView.currentItem) {
            root.appLaunched(listView.currentItem.appEntry)
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        spacing: 4
        clip: true
        
        delegate: AppResult {
            appEntry: modelData
            onLaunchRequested: root.appLaunched(appEntry)
        }
        
        // Scrollbar
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            background: Rectangle { color: "transparent" }
            contentItem: Rectangle {
                color: Services.Theme.accent
                opacity: 0.3
                radius: 2
            }
        }
    }
}
