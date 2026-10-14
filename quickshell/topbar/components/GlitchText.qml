import QtQuick
import "../services" as Services

Text {
    id: root
    
    // The actual text to display/converge to
    property string textData: ""
    
    // Configuration
    property bool triggerOnStart: true
    property bool triggerOnTextChanged: true
    property int glitchInterval: 80
    property int totalTicks: 15
    property int periodicInterval: 0 // 0 to disable periodic glitching
    
    // Internal state
    property string displayString: textData
    property int glitchTick: 0
    
    text: displayString
    font.family: "JetBrains Mono" // Standard for the theme
    
    function startGlitch() {
        glitchTick = 0;
        glitchTimer.start();
    }
    
    onTextDataChanged: {
        if (triggerOnTextChanged) startGlitch();
        else displayString = textData;
    }
    
    Timer {
        id: glitchTimer
        interval: root.glitchInterval
        repeat: true
        onTriggered: {
            if (root.glitchTick >= root.totalTicks) {
                root.displayString = root.textData;
                stop();
                return;
            }
            
            let chars = "X01_&%#@!<>?[]{}";
            let result = "";
            let raw = root.textData;
            
            for (let i = 0; i < raw.length; i++) {
                if (raw[i] === " ") {
                    result += " ";
                } else {
                    // Convergence logic: chance to show correct char increases with ticks
                    let probability = root.glitchTick / root.totalTicks;
                    if (Math.random() < probability) {
                        result += raw[i];
                    } else {
                        result += chars[Math.floor(Math.random() * chars.length)];
                    }
                }
            }
            
            root.displayString = result;
            root.glitchTick++;
        }
    }
    
    Timer {
        id: periodicTimer
        interval: root.periodicInterval
        running: root.periodicInterval > 0
        repeat: true
        triggeredOnStart: root.triggerOnStart
        onTriggered: root.startGlitch()
    }
    
    Component.onCompleted: {
        if (triggerOnStart && periodicInterval <= 0) {
            startGlitch();
        }
    }
}
