import QtQuick
import QtQuick.Layouts
import "../services" as Services

// Canonical outer frame for every topbar island. Callers provide only their
// placement, sizing, and content; surface and border treatment live here.
Rectangle {
    id: root

    default property alias content: contentLayout.data

    property string title: ""
    property bool showBrackets: true
    property color accentColor: Services.Theme.accent
    property real padding: 3
    property real titleLeftInset: 10
    property real titleContentGap: 8
    readonly property real titleRailWidth: title !== "" ? titleLeftInset + 8 : 0
    readonly property real contentAvailableWidth: Math.max(0, width - padding * 2 - titleRailWidth - (title !== "" ? titleContentGap : 0))

    implicitWidth: innerLayout.implicitWidth + padding * 2
    implicitHeight: innerLayout.implicitHeight + padding * 2

    color: Services.Theme.surface
    radius: 4
    border.width: 1
    border.color: Services.Theme.border

    Rectangle {
        visible: root.showBrackets
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: parent.radius
        anchors.bottomMargin: parent.radius
        width: 2
        color: root.accentColor
        opacity: 0.8
    }

    Rectangle {
        visible: root.showBrackets
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: parent.radius
        anchors.bottomMargin: parent.radius
        width: 2
        color: root.accentColor
        opacity: 0.8
    }

    RowLayout {
        id: innerLayout
        anchors.centerIn: parent
        spacing: root.title !== "" ? root.titleContentGap : 0

        // Every island gets the same vertical title rail. Content components
        // therefore contain only their functional UI.
        Item {
            id: titleRail
            visible: root.title !== ""
            Layout.preferredWidth: visible ? root.titleRailWidth : 0
            Layout.fillHeight: true

            Item {
                id: titleGlyph
                anchors.left: parent.left
                anchors.leftMargin: root.titleLeftInset
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 8

                Text {
                    anchors.centerIn: parent
                    text: root.title
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: root.accentColor
                    opacity: 0.5
                    rotation: -90
                    width: 30
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height - 8
                    color: root.accentColor
                    opacity: 0.2
                }
            }
        }

        RowLayout {
            id: contentLayout
            spacing: 0
        }
    }

    Repeater {
        model: root.showBrackets ? 4 : 0
        delegate: Rectangle {
            width: 3
            height: 3
            color: root.accentColor
            opacity: 0.9

            anchors.top: index < 2 ? parent.top : undefined
            anchors.bottom: index >= 2 ? parent.bottom : undefined
            anchors.left: index % 2 === 0 ? parent.left : undefined
            anchors.right: index % 2 !== 0 ? parent.right : undefined
            // Keep blocks inside the island bounds so clipped islands render
            // the exact same bracket frame as every other island.
            anchors.margins: 0
        }
    }
}
