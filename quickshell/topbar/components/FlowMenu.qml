import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as Services

Item {
    id: root
    
    property Item attachTo
    property color surfaceColor: Services.Theme.surface
    property color accentColor: Services.Theme.accent
    property bool active: false
    
    property string verticalLabel: ""
    
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

    function updatePosition() {
        if (!attachTo || !parent) return;
        
        // Get absolute position of the button
        let absPos = attachTo.mapToItem(null, 0, 0);
        // Map it back to our parent's coordinate system
        let localPos = parent.mapFromItem(null, absPos.x, absPos.y);
        
        let centerX = localPos.x + attachTo.width / 2 - width / 2;
        x = Math.max(12, Math.min(parent.width - width - 12, centerX));
        y = Math.round(localPos.y + attachTo.height + 18);
    }

    onActiveChanged: if (active) updatePosition()
    onAttachToChanged: updatePosition()
    onWidthChanged: updatePosition()

    // --- DEPTH: SIMULATED SHADOW ---
    // Fixed: Set topMargin to container.radius to completely prevent shadow bleed in rounded corners
   // Rectangle {
   //     anchors.fill: container
   //     anchors.leftMargin: -4
   //     anchors.rightMargin: -4
   //     anchors.bottomMargin: -6
   //     anchors.topMargin: container.radius
   //     color: Services.Theme.shadow
   //     radius: 0
   //     visible: root.animationProgress > 0.5
   //     opacity: root.animationProgress * 0.8
   //     z: -1
   // }

    // --- FLOW CONNECTOR (Vertical from Top) ---
    // Moved outside the clipped container to ensure it renders correctly
    Rectangle {
        id: connector
        anchors.horizontalCenter: container.horizontalCenter
        anchors.bottom: container.top
        width: 12; height: 4
        color: root.surfaceColor
        border.width: 1; border.color: Services.Theme.border
        visible: root.animationProgress > 0.1
        z: 5
        
        // Mask the bottom border of the connector to "merge" with container
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: -1
            width: parent.width - 2; height: 2
            color: root.surfaceColor
        }
    }

    Rectangle {
        id: container
        
        readonly property real labelAreaWidth: root.verticalLabel !== "" ? 20 : 0
        readonly property real targetHeight: contentWrapper.implicitHeight + 32
        readonly property real targetWidth: contentWrapper.implicitWidth + 32 + container.labelAreaWidth * 2
        
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        // --- DUAL AXIS ANIMATION ---
        width: targetWidth * root.animationProgress
        height: targetHeight * root.animationProgress
        
        color: root.surfaceColor
        radius: 4 
        border.width: 1
        border.color: Services.Theme.border
        
        clip: true
        opacity: Math.min(1.0, root.animationProgress * 5) 

        // --- SIDE BRACKETS (Match Island Style) ---
        // Added top/bottomMargin to prevent overlapping rounded corners
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

        // --- DECORATIVE: VERTICAL LABEL ---
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
                font.pixelSize: 9
                color: root.accentColor
                opacity: 0.5 * root.animationProgress
                rotation: -90
                width: 60
                horizontalAlignment: Text.AlignHCenter
            }
            
            // Vertical anchor bar
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: parent.height - 16
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

        // --- ARKNIGHTS: TECHNICAL BACKGROUND NOISE ---
        Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 8
            text: "ID_FLOW_" + Math.round(root.width) + "x" + Math.round(root.height)
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            color: root.accentColor
            opacity: 0.15
            visible: root.animationProgress > 0.9
        }
        
        // Content Area - Centered for balance
        ColumnLayout {
            id: contentWrapper
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            
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
            readonly property real targetX: index % 2 == 0 ? -1 : root.width - width + 1
            readonly property real targetY: index < 2 ? -1 : container.targetHeight - height + 1
            
            x: startX + (targetX - startX) * root.animationProgress
            y: startY + (targetY - startY) * root.animationProgress
        }
    }
}
