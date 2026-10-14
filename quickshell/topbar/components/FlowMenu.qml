import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../services" as Services

Item {
    id: root

    property Item attachTo
    property color surfaceColor: Services.Theme.surface
    property color accentColor: Services.Theme.accent
    property bool active: false
    property bool expandFromRight: false
    property string verticalLabel: ""
    property real maxMenuHeight: 640

    signal closeRequested()
    signal statusRequested(string message)

    default property alias content: contentWrapper.data

    visible: active || animationProgress > 0.01
    focus: active

    property real animationProgress: active ? 1.0 : 0.0
    Behavior on animationProgress {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutExpo
        }
    }

    width: container.targetWidth
    height: container.targetHeight

    function updatePosition() {
        if (!attachTo || !parent)
            return;

        const absolutePosition = attachTo.mapToItem(null, 0, 0);
        const localPosition = parent.mapFromItem(null, absolutePosition.x, absolutePosition.y);
        const desiredY = Math.round(localPosition.y + attachTo.height + 18);

        maxMenuHeight = Math.max(96, parent.height - desiredY - 12);
        const desiredX = expandFromRight
            ? localPosition.x + attachTo.width - width
            : localPosition.x + attachTo.width / 2 - width / 2;
        x = Math.max(12, Math.min(parent.width - width - 12, desiredX));
        y = Math.max(0, Math.min(parent.height - height - 12, desiredY));
    }

    onActiveChanged: {
        if (active) {
            updatePosition();
            forceActiveFocus();
        }
    }
    onAttachToChanged: updatePosition()
    onWidthChanged: updatePosition()
    onHeightChanged: updatePosition()

    Keys.onEscapePressed: event => {
        event.accepted = true;
        root.closeRequested();
    }

    Connections {
        target: root.parent
        function onWidthChanged() { root.updatePosition(); }
        function onHeightChanged() { root.updatePosition(); }
    }

    Rectangle {
        id: connector
        anchors.horizontalCenter: root.expandFromRight ? undefined : container.horizontalCenter
        anchors.right: root.expandFromRight ? container.right : undefined
        anchors.rightMargin: root.expandFromRight ? 8 : 0
        anchors.bottom: container.top
        width: 12
        height: 4
        color: root.surfaceColor
        border.width: 1
        border.color: Services.Theme.border
        visible: root.animationProgress > 0.1
        z: 5

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: -1
            width: parent.width - 2
            height: 2
            color: root.surfaceColor
        }
    }

    Rectangle {
        id: container

        readonly property real labelAreaWidth: root.verticalLabel !== "" ? 20 : 0
        readonly property real unconstrainedWidth: contentWrapper.implicitWidth + 32 + labelAreaWidth * 2
        readonly property real targetWidth: Math.max(0, Math.min(unconstrainedWidth, (root.parent?.width ?? unconstrainedWidth) - 24))
        readonly property real targetHeight: Math.min(contentWrapper.implicitHeight + 32, root.maxMenuHeight)

        anchors.top: parent.top
        anchors.horizontalCenter: root.expandFromRight ? undefined : parent.horizontalCenter
        anchors.right: root.expandFromRight ? parent.right : undefined
        width: targetWidth * root.animationProgress
        height: targetHeight * root.animationProgress

        color: root.surfaceColor
        radius: 4
        border.width: 1
        border.color: Services.Theme.border
        clip: true
        opacity: Math.min(1.0, root.animationProgress * 5)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: parent.radius
            anchors.bottomMargin: parent.radius
            width: 2
            color: root.accentColor
            opacity: 0.8 * root.animationProgress
        }

        Item {
            visible: root.verticalLabel !== ""
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 14

            Text {
                anchors.centerIn: parent
                text: root.verticalLabel
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: root.accentColor
                opacity: 0.5 * root.animationProgress
                rotation: -90
                width: 60
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height - 16
                color: root.accentColor
                opacity: 0.2 * root.animationProgress
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: parent.radius
            anchors.bottomMargin: parent.radius
            width: 2
            color: root.accentColor
            opacity: 0.8 * root.animationProgress
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 8
            text: "ID_FLOW_" + Math.round(root.width) + "x" + Math.round(root.height)
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: root.accentColor
            opacity: 0.15
            visible: root.animationProgress > 0.9
        }

        Flickable {
            id: contentViewport
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            anchors.leftMargin: 16 + container.labelAreaWidth
            anchors.rightMargin: 16 + container.labelAreaWidth
            contentWidth: width
            contentHeight: contentWrapper.implicitHeight
            interactive: contentHeight > height
            clip: true

            ColumnLayout {
                id: contentWrapper
                x: Math.max(0, (contentViewport.width - width) / 2)
                width: implicitWidth
                spacing: 0
                opacity: Math.max(0, root.animationProgress * 4 - 3)
            }

            ScrollBar.vertical: ScrollBar {
                policy: contentViewport.contentHeight > contentViewport.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                width: 4
                background: Rectangle { color: "transparent" }
                contentItem: Rectangle {
                    color: root.accentColor
                    opacity: 0.45
                    radius: 2
                }
            }
        }
    }

    Repeater {
        model: 4
        delegate: Rectangle {
            width: 3
            height: 3
            color: root.accentColor
            opacity: 0.9
            visible: root.animationProgress > 0.01
            z: 100

            readonly property real startX: root.expandFromRight ? root.width - width : root.width / 2 - width / 2
            readonly property real targetX: index % 2 === 0 ? -1 : root.width - width + 1
            readonly property real targetY: index < 2 ? -1 : container.targetHeight - height + 1

            x: startX + (targetX - startX) * root.animationProgress
            y: targetY * root.animationProgress
        }
    }
}
