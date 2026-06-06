pragma Singleton
import QtQuick

Item {
    id: root

    // --- THEME TOGGLE ---
    property bool isLightMode: false

    // --- COLOR PALETTES ---

    // Ghost Lavender Dark
    QtObject {
        id: darkPalette
        property color surface: "#1A1C1E"
        property color accent: "#A78BFA"
        property color muted: "#64748B"
        property color highlight: "#F8FAFC"
        property color border: Qt.rgba(255, 255, 255, 0.05)
        property color danger: "#EF4444"
        property color success: "#22C55E"
        property color warning: "#F59E0B"
        property color track: Qt.rgba(255, 255, 255, 0.12)
        property color surfaceLighter: Qt.rgba(255, 255, 255, 0.05)
        property color surfaceDarker: "#0F1112"
        property color shadow: Qt.rgba(0, 0, 0, 0.8)
    }

    // Moss & Earth Light (Complements natural greens)
    QtObject {
        id: lightPalette
        property color surface: "#F4F6F4"        // Slightly warm, earthy off-white
        property color accent: "#4A7c59"         // Deep moss green
        property color muted: "#889A88"          // Desaturated earthy grey-green
        property color highlight: "#1D2B22"      // Very dark forest slate for primary text
        property color border: Qt.rgba(0, 0, 0, 0.08)
        property color danger: "#D94436"         // Terracotta red
        property color success: "#3B9954"        // Leaf green
        property color warning: "#D97B29"        // Ochre orange
        property color track: Qt.rgba(0, 0, 0, 0.15)
        property color surfaceLighter: Qt.rgba(0, 0, 0, 0.04) // Acts as a hover/highlight in light mode
        property color surfaceDarker: "#E5E8E5"
        property color shadow: Qt.rgba(0, 0, 0, 0.15)
    }

    // --- ACTIVE THEME BINDINGS ---
    readonly property var active: isLightMode ? lightPalette : darkPalette

    readonly property color surface: active.surface
    readonly property color accent: active.accent
    readonly property color muted: active.muted
    readonly property color highlight: active.highlight
    readonly property color border: active.border
    readonly property color danger: active.danger
    readonly property color success: active.success
    readonly property color warning: active.warning
    readonly property color track: active.track
    readonly property color surfaceLighter: active.surfaceLighter
    readonly property color surfaceDarker: active.surfaceDarker
    readonly property color shadow: active.shadow
}
