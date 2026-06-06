import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as Services

Item {
    id: root
    property var appEntry
    property bool isSelected: ListView.isCurrentItem
    
    signal launchRequested()
    
    implicitWidth: ListView.view.width
    implicitHeight: 60

    readonly property color baseColor: root.isSelected ? Services.Theme.accent : Services.Theme.muted

    // --- HIGHLIGHT ANIMATION (From SKILL.md) ---
    property bool showHighlight: root.isSelected || mouseArea.containsMouse
    
    Rectangle {
        id: highlightFrame
        anchors.centerIn: parent
        width: parent.width + (root.showHighlight ? 4 : -4)
        height: parent.height + (root.showHighlight ? 4 : -4)
        opacity: root.showHighlight ? 0.3 : 0
        color: "transparent"
        border.width: 1
        border.color: root.baseColor
        radius: 4
        
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Repeater {
            model: 4
            Rectangle {
                width: 4; height: 4
                color: root.baseColor
                opacity: highlightFrame.opacity * 2
                
                anchors.top: index < 2 ? parent.top : undefined
                anchors.bottom: index >= 2 ? parent.bottom : undefined
                anchors.left: index % 2 == 0 ? parent.left : undefined
                anchors.right: index % 2 != 0 ? parent.right : undefined
                anchors.margins: -1
            }
        }
    }

    // --- BACKGROUND WASH ---
    Rectangle {
        anchors.fill: parent
        color: root.isSelected ? Services.Theme.accent : Services.Theme.surfaceLighter
        opacity: root.isSelected ? 0.15 : (mouseArea.containsMouse ? 0.08 : 0)
        radius: 4
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // Selected Side Indicator
    Rectangle {
        visible: root.isSelected
        width: 4
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 4
        color: Services.Theme.accent
        radius: 2
    }

    // --- WATERMARK UNDERLAY (Information-as-texture) ---
    GlitchText {
        anchors.fill: parent
        anchors.margins: 8
        
        textData: (appEntry?.name ?? "").toUpperCase()
        triggerOnTextChanged: false // We control triggering via isSelected
        periodicInterval: 20000 + Math.random() * 15000
        totalTicks: 15
        glitchInterval: 80
        
        property bool selected: root.isSelected
        onSelectedChanged: if (selected) startGlitch()

        font.pixelSize: 42 // Larger texture
        font.bold: true
        color: root.isSelected ? Services.Theme.accent : root.baseColor
        opacity: root.isSelected ? 0.12 : 0.04
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignBottom
        clip: true
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16
        
        // App Icon
        Rectangle {
            width: 40; height: 40
            color: "transparent"
            
            // Icon rendering (Simple for now, could use a real icon provider)
            Text {
                anchors.centerIn: parent
                text: "󰀻" // Default app icon
                font.family: "JetBrains Mono"
                font.pixelSize: 32
                color: root.baseColor
            }
        }

        // Micro-Data Column
        Column {
            spacing: -2
            Layout.fillWidth: true
            
            Text {
                text: appEntry?.name ?? "Unknown Application"
                font.family: "JetBrains Mono"
                font.pixelSize: 14
                font.bold: true
                color: root.isSelected ? Services.Theme.accent : Services.Theme.highlight
            }
            
            Text {
                text: appEntry?.comment || appEntry?.execString || "SYS_PROCESS_ENTRY"
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                color: Services.Theme.muted
                elide: Text.ElideRight
                width: parent.width - 20
            }
        }
        
        // Technical ID
        GlitchText {
            textData: "0x" + (index + 100).toString(16).toUpperCase()
            triggerOnTextChanged: false
            periodicInterval: 20000 + Math.random() * 15000
            totalTicks: 15
            glitchInterval: 80
            
            property bool selected: root.isSelected
        onSelectedChanged: if (selected) startGlitch()

            font.pixelSize: 9
            color: root.baseColor
            opacity: 0.4
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.launchRequested()
    }
}
