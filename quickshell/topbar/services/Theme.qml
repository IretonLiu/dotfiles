pragma Singleton
import QtQuick

Item {
    // --- CURRENT THEME: GHOST LAVENDER DARK ---
    readonly property color surface: "#1A1C1E"
    readonly property color accent: "#A78BFA"
    readonly property color muted: "#64748B"
    readonly property color highlight: "#F8FAFC"
    readonly property color border: Qt.rgba(255, 255, 255, 0.05)
    
    // Status Colors
    readonly property color danger: "#EF4444"
    readonly property color success: "#22C55E"
    readonly property color warning: "#F59E0B"
    
    // UI Elements
    readonly property color track: Qt.rgba(255, 255, 255, 0.12) // Better contrast for bars
    readonly property color surfaceLighter: Qt.rgba(255, 255, 255, 0.05)
    readonly property color surfaceDarker: "#0F1112"
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.4)
}
