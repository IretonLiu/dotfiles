import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    
    property Item attachTo
    property color surfaceColor: "#F8FAFC"
    property color accentColor: "#334155"
    property bool active: false
    
    default property alias content: contentWrapper.data
    
    visible: active || animationProgress > 0.01
    
    property real animationProgress: active ? 1.0 : 0.0
    Behavior on animationProgress { 
        NumberAnimation { 
            duration: 500
            easing.type: Easing.OutExpo 
        } 
    }
    
    // --- POSITIONING: VERTICAL DROPDOWN ---
    width: container.targetWidth
    height: container.targetHeight

    // Horizontal centering with screen edge clamping
    x: {
        if (!attachTo || !parent) return parent ? parent.width - width - 12 : 0;
        let mappedX = attachTo.mapToItem(parent, 0, 0).x;
        let centerX = mappedX + attachTo.width / 2 - width / 2;
        return Math.max(12, Math.min(parent.width - width - 12, centerX));
    }
    
    // Positioned directly below the button
    y: attachTo ? Math.round(attachTo.mapToItem(parent, 0, 0).y + attachTo.height + 18) : 12

    Rectangle {
        id: container
        
        readonly property real targetHeight: contentWrapper.implicitHeight + 32
        readonly property real targetWidth: contentWrapper.implicitWidth + 32
        
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        // --- DUAL AXIS ANIMATION ---
        // Expands both horizontally from center and vertically downwards
        width: targetWidth * root.animationProgress
        height: targetHeight * root.animationProgress
        
        color: root.surfaceColor
        radius: 8
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.1)
        
        clip: true
        opacity: Math.min(1.0, root.animationProgress * 5) 

        // --- FLOW CONNECTOR (Vertical from Top) ---
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            width: 12; height: 4
            color: root.surfaceColor
            border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.1)
            visible: root.animationProgress > 0.05
            
            // Mask the bottom border of the connector to "merge" with container
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2; height: 2
                color: root.surfaceColor
            }
        }
        
        // Content Area
        ColumnLayout {
            id: contentWrapper
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Note: We don't set a width here to allow it to use its implicit size.
            // But we use opacity to hide it while the container is small.
            spacing: 0 
            opacity: Math.max(0, root.animationProgress * 4 - 3)
        }
    }
    
    // --- PROJECTOR ANCHORS (Dual Axis Reveal) ---
    Repeater {
        model: 4
        delegate: Rectangle {
            width: 3; height: 3
            color: root.accentColor
            opacity: 0.9
            visible: root.animationProgress > 0.01
            z: 100 
            
            // Start: Top-Center
            readonly property real startX: root.width / 2 - width / 2
            readonly property real startY: 0
            
            // End: Corners
            readonly property real targetX: index % 2 == 0 ? 0 : root.width - width
            readonly property real targetY: index < 2 ? 0 : root.height - height
            
            // Calculate position relative to root
            x: startX + (targetX - startX) * root.animationProgress
            y: startY + (targetY - startY) * root.animationProgress
        }
    }
}
