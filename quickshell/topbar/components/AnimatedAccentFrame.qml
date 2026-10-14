import QtQuick

// Shared animated outline used by interactive topbar controls. The parent
// keeps ownership of pointer handling; this item is purely decorative.
Item {
    id: root

    property bool active: false
    property color accentColor: "white"
    property real activeOpacity: 0.3
    property real activeSizeDelta: 4
    property int duration: 300

    anchors.centerIn: parent
    width: parent ? Math.max(0, parent.width + (active ? activeSizeDelta : -activeSizeDelta)) : 0
    height: parent ? Math.max(0, parent.height + (active ? activeSizeDelta : -activeSizeDelta)) : 0
    opacity: active ? activeOpacity : 0

    Behavior on width {
        NumberAnimation { duration: root.duration; easing.type: Easing.OutQuint }
    }
    Behavior on height {
        NumberAnimation { duration: root.duration; easing.type: Easing.OutQuint }
    }
    Behavior on opacity {
        NumberAnimation { duration: root.duration }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: root.accentColor
        radius: 4
    }

    Repeater {
        model: 4
        Rectangle {
            width: 4
            height: 4
            color: root.accentColor
            opacity: root.opacity * 2

            anchors.top: index < 2 ? parent.top : undefined
            anchors.bottom: index >= 2 ? parent.bottom : undefined
            anchors.left: index % 2 === 0 ? parent.left : undefined
            anchors.right: index % 2 !== 0 ? parent.right : undefined
            anchors.margins: -1
        }
    }
}
