import QtQuick
import QtQuick.Layouts
import "../services" as Services

Item {
    id: root
    
    signal textChanged(string text)
    signal accepted()
    signal ctrlAccepted()

    property bool ctrlEnterEnabled: false
    property string iconText: "󰍉"
    property string titleText: "APP_QUERY"
    property string subtitleText: "EXEC_SEARCH"
    
    function forceActiveFocus() {
        textInput.forceActiveFocus()
    }

    function clear() {
        textInput.text = ""
        root.textChanged("")
    }

    function setText(value) {
        textInput.text = value
        textInput.cursorPosition = textInput.text.length
        root.textChanged(textInput.text)
        textInput.forceActiveFocus()
    }

    function insertText(value) {
        textInput.insert(textInput.cursorPosition, value)
        root.textChanged(textInput.text)
        textInput.forceActiveFocus()
    }

    function handleEnter(event) {
        const modifiers = event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)
        const ctrlOnly = (modifiers & Qt.ControlModifier) && !(modifiers & (Qt.ShiftModifier | Qt.AltModifier | Qt.MetaModifier))

        if (ctrlOnly && root.ctrlEnterEnabled) {
            root.ctrlAccepted()
            event.accepted = true
            return
        }

        if (modifiers === 0) {
            root.accepted()
            event.accepted = true
            return
        }

        event.accepted = false
    }
    
    // Base background wash
    Rectangle {
        anchors.fill: parent
        color: textInput.activeFocus ? Qt.rgba(Services.Theme.accent.r, Services.Theme.accent.g, Services.Theme.accent.b, 0.05) : "transparent"
        radius: 2
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // Technical Bottom Underline (Docking Plate)
    Rectangle {
        id: bottomLine
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: textInput.activeFocus ? parent.width : parent.width - 40
        height: 2
        color: textInput.activeFocus ? Services.Theme.accent : Services.Theme.muted
        opacity: textInput.activeFocus ? 0.8 : 0.3
        
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on color { ColorAnimation { duration: 200 } }
        
        // Left End Bracket
        Rectangle {
            width: 2; height: 8
            anchors.bottom: parent.top
            anchors.left: parent.left
            color: parent.color
            opacity: parent.opacity
        }
        
        // Right End Bracket
        Rectangle {
            width: 2; height: 8
            anchors.bottom: parent.top
            anchors.right: parent.right
            color: parent.color
            opacity: parent.opacity
        }
    }

    // Top Corner L-Brackets (Appear on focus)
    Item {
        anchors.fill: parent
        opacity: textInput.activeFocus ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        // Top Left
        Rectangle { width: 10; height: 2; color: Services.Theme.accent; anchors.left: parent.left; anchors.top: parent.top }
        Rectangle { width: 2; height: 10; color: Services.Theme.accent; anchors.left: parent.left; anchors.top: parent.top }
        
        // Top Right
        Rectangle { width: 10; height: 2; color: Services.Theme.accent; anchors.right: parent.right; anchors.top: parent.top }
        Rectangle { width: 2; height: 10; color: Services.Theme.accent; anchors.right: parent.right; anchors.top: parent.top }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 8
        spacing: 12
        
        Text {
            text: root.iconText
            font.family: "JetBrains Mono"
            font.pixelSize: 24
            color: textInput.activeFocus ? Services.Theme.accent : Services.Theme.muted
        }
        
        Column {
            spacing: -2
            Layout.alignment: Qt.AlignVCenter
            
            Text {
                text: root.titleText
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.bold: true
                color: Services.Theme.highlight
            }
            
            Text {
                text: root.subtitleText
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                font.weight: Font.Bold
                color: Services.Theme.muted
            }
        }
        
        // Vertical divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Services.Theme.border
        }

        TextInput {
            id: textInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: TextInput.AlignVCenter
            
            font.family: "JetBrains Mono"
            font.pixelSize: 18
            color: Services.Theme.highlight
            
            clip: true
            selectByMouse: true
            selectionColor: Services.Theme.accent
            
            onTextEdited: root.textChanged(text)
            onAccepted: root.accepted()
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.handleEnter(event)
            }
        }
    }
}
