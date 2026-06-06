import QtQuick
import QtQuick.Layouts
import "../services" as Services

Rectangle {
    id: root
    
    default property alias content: innerLayout.data
    property bool showBrackets: true
    property color accentColor: Services.Theme.accent
    property real padding: 10

    implicitWidth: innerLayout.implicitWidth + padding * 2
    implicitHeight: innerLayout.implicitHeight + padding * 2

    // --- DARK OPAQUE SURFACE ---
    color: Services.Theme.surface 
    radius: 4
    
    border.width: 1
    border.color: Services.Theme.border

    // --- SIDE BRACKETS (Arknights Style) ---
    // Added top/bottomMargin to prevent overlapping rounded corners
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
        spacing: 0
    }

    // --- REFINED SQUARE ANCHORS ---
    Repeater {
        model: root.showBrackets ? 4 : 0
        delegate: Rectangle {
            width: 3; height: 3
            color: root.accentColor
            opacity: 0.9
            
            anchors.top: index < 2 ? parent.top : undefined
            anchors.bottom: index >= 2 ? parent.bottom : undefined
            anchors.left: index % 2 == 0 ? parent.left : undefined
            anchors.right: index % 2 != 0 ? parent.right : undefined
            
            anchors.margins: -1
        }
    }
}
