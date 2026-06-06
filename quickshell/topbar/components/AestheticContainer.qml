import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    
    default property alias content: innerLayout.data
    property bool showBrackets: true
    property color accentColor: "#334155"
    property real padding: 10

    implicitWidth: innerLayout.implicitWidth + padding * 2
    implicitHeight: innerLayout.implicitHeight + padding * 2

    color: "#F8FAFC" // Opaque Off-White
    radius: 4 // Sharper Nordic rounding
    
    border.width: 1
    border.color: Qt.rgba(0, 0, 0, 0.08)

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
