pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // --- THEME STATE PERSISTENCE ---
    readonly property string stateFile: Quickshell.env("HOME") + "/.cache/quickshell-theme-state"
    
    // Default to true, but will be overwritten by file content
    property bool isLightMode: true
    
    FileView {
        path: root.stateFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let data = text().trim();
            if (data === "dark") root.isLightMode = false;
            else if (data === "light") root.isLightMode = true;
        }
    }
    
    function toggle() {
        let next = !isLightMode;
        // Persist to file - this will trigger onLoaded in all processes watching the file
        themeWriter.run(["sh", "-c", "echo " + (next ? "light" : "dark") + " > " + root.stateFile]);
    }
    
    Process {
        id: themeWriter
        function run(args) {
            command = args;
            running = true;
        }
    }

    // --- ACTIVE THEME BINDINGS ---
    property color surface: isLightMode ? "#E8EBE4" : "#1A1C1E"
    property color accent: isLightMode ? "#4A7c59" : "#A78BFA"
    property color muted: isLightMode ? "#7C8C7C" : "#64748B"
    property color highlight: isLightMode ? "#1D2B22" : "#F8FAFC"
    
    property color border: isLightMode ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(255, 255, 255, 0.05)
    
    property color danger: isLightMode ? "#D94436" : "#EF4444"
    property color success: isLightMode ? "#3B9954" : "#22C55E"
    property color warning: isLightMode ? "#D97B29" : "#F59E0B"
    
    property color track: isLightMode ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(255, 255, 255, 0.12)
    property color surfaceLighter: isLightMode ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(255, 255, 255, 0.05)
    property color surfaceDarker: isLightMode ? "#D8DDD8" : "#0F1112"
    property color shadow: isLightMode ? Qt.rgba(0, 0, 0, 0.20) : Qt.rgba(0, 0, 0, 0.8)
}
