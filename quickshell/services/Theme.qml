pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // `~/dotfiles/scripts/theme apply <profile>` is the desktop-wide source of
    // truth. A complete palette is written atomically, so open Quickshell
    // surfaces update without being restarted.
    readonly property string paletteFile: Quickshell.env("HOME") + "/.local/state/dotfiles-theme/quickshell.json"
    readonly property string changeMarkerFile: Quickshell.env("HOME") + "/.cache/quickshell-theme-state"
    readonly property string themeCommand: Quickshell.env("HOME") + "/dotfiles/scripts/theme"

    // A dark fallback keeps the shell legible before the first `theme apply`.
    property var palette: ({
        "profile": "dark",
        "mode": "dark",
        "surface": "#1B1826",
        "surface_lighter": "#252037",
        "surface_darker": "#12101A",
        "accent": "#A78BFA",
        "muted": "#A49AB8",
        "highlight": "#F5F0E8",
        "border": "#4A4262",
        "track": "#3B3450",
        "shadow": "#46385F",
        "danger": "#E58AA6",
        "success": "#72C7AA",
        "warning": "#E5B875"
    })

    readonly property bool isLightMode: palette.mode === "light"
    readonly property string profile: palette.profile ?? "dark"

    FileView {
        id: paletteView
        path: root.paletteFile
        onLoaded: {
            try {
                const nextPalette = JSON.parse(text());
                const required = ["mode", "surface", "surface_lighter", "surface_darker", "accent", "muted", "highlight", "border", "track", "shadow", "danger", "success", "warning"];
                if (required.every(key => typeof nextPalette[key] === "string"))
                    root.palette = nextPalette;
                else
                    console.warn("Ignoring incomplete shared theme palette");
            } catch (error) {
                console.warn("Could not load shared theme palette:", error);
            }
        }
    }

    // The palette itself is atomically replaced. FileView watches file inodes,
    // so an in-place marker reliably triggers a reload in already-open shells.
    FileView {
        path: root.changeMarkerFile
        watchChanges: true
        onLoaded: paletteView.reload()
        onFileChanged: paletteView.reload()
    }

    function toggle() {
        themeApplier.run(isLightMode ? "dark" : "light");
    }

    Process {
        id: themeApplier

        function run(nextProfile) {
            command = [root.themeCommand, "apply", nextProfile];
            running = true;
        }
    }

    property color surface: palette.surface
    property color accent: palette.accent
    property color muted: palette.muted
    property color highlight: palette.highlight
    property color border: palette.border
    property color danger: palette.danger
    property color success: palette.success
    property color warning: palette.warning
    property color track: palette.track
    property color surfaceLighter: palette.surface_lighter
    property color surfaceDarker: palette.surface_darker
    property color shadow: palette.shadow
}
