# Topbar Designer Skill

This skill documents the exact QML design schema, typography conventions, and "information-as-texture" aesthetics used for the Caelestia Quickshell Topbar. Whenever creating or modifying components in `topbar/components`, you MUST adhere to these architectural rules to maintain visual consistency.

## 1. Core Typography & The "Information-as-Texture" Aesthetic

The topbar uses a dense, technical, Arknights-inspired aesthetic. Information isn't just displayed; it acts as visual texture to fill empty space.

- **Font Family**: ALL text must use `"JetBrains Mono"` (Nerd Font).
- **Icons**: Utilize Nerd Font glyphs at `pixelSize: 20` or `24` depending on the button context, colored by the active item's `baseColor`.
- **Vertical Labels**: Large container blocks often feature a 90-degree rotated label (e.g., `SYS`, `CLK`, `WS`) fading into the background (`opacity: 0.5`, `pixelSize: 9`), attached to a 1px vertical tracking bar.
- **Micro-Data Columns**: Action buttons usually feature a `Column` with `spacing: -2`.
  - Top text (Main Label): `pixelSize: 11`, `font.bold: true`, colored with `Services.Theme.highlight`.
  - Bottom text (Sublabel): `pixelSize: 7` or `8`, colored with `Services.Theme.muted`. It often acts as a technical identifier (e.g., `SYS_HALT`, `BT_SERVICE`).
- **Watermark Underlays**: For expanding components (like the Workspaces), active data (like the Window Title) should be rendered huge (`pixelSize: 20`), bold, and semi-transparent (`opacity: 0.15` to `0.4`), anchored behind the main content to fill the layout.

## 2. Universal Hover & Highlight Animation

All interactive buttons (`MouseArea`) must feature a dual-layer hover effect that feels mechanical and precise:

1.  **Background Wash**: A rectangle filling the button that activates on hover:
    ```qml
    Rectangle {
        anchors.fill: parent
        color: baseColor // The button's base accent color
        opacity: parent.containsMouse ? 0.1 : 0
        radius: 4
    }
    ```
2.  **The "Scanning Corner" Frame**: An outline that expands slightly outward on hover, punctuated by 4 corner tracking squares.
    ```qml
    property bool showHighlight: containsMouse // Bind this to the MouseArea

    Rectangle {
        id: highlightFrame
        anchors.centerIn: parent
        width: parent.width + (showHighlight ? 4 : -4)
        height: parent.height + (showHighlight ? 4 : -4)
        opacity: showHighlight ? 0.3 : 0
        color: "transparent"
        border.width: 1
        border.color: baseColor
        radius: 4
        
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Repeater {
            model: 4
            Rectangle {
                width: 4; height: 4
                color: baseColor
                opacity: highlightFrame.opacity * 2
                
                anchors.top: index < 2 ? parent.top : undefined
                anchors.bottom: index >= 2 ? parent.bottom : undefined
                anchors.left: index % 2 == 0 ? parent.left : undefined
                anchors.right: index % 2 != 0 ? parent.right : undefined
                anchors.margins: -1
            }
        }
    }
    ```

## 3. Dynamic State & Coloring

Colors must never be hardcoded strings. Always bind to `Services.Theme`.

- **Base References**: `Services.Theme.surface`, `Services.Theme.accent`, `Services.Theme.highlight`, `Services.Theme.muted`.
- **Dynamic Action Colors**: If a button changes state (e.g., Muted/Unmuted, Connected/Disconnected), define a `readonly property color baseColor` on the `MouseArea` that switches between the normal accent and a status color:
  ```qml
  readonly property bool isConnected: Services.Nmcli.isConnected
  readonly property color baseColor: isConnected ? Services.Theme.success : Services.Theme.danger
  ```
- All inner components (Icons, Text, Hover effects, Corner bounds) MUST reference this `baseColor` to ensure the entire button block shifts simultaneously without needing to manually toggle colors across 5 different rectangles.

## 4. Centering and Anchors vs. Layouts

- **Never mix Anchors and Layouts**: If an Item is inside a `RowLayout` or `ColumnLayout`, NEVER use `anchors.centerIn`, `anchors.left`, etc. Use `Layout.alignment`, `Layout.fillWidth`, and `horizontalAlignment` instead to prevent QML engine undefined behavior.
- **Absolute Centering**: To guarantee a component remains perfectly centered in the screen (even if other components change width dynamically), isolate it in an `Item` container with `anchors.centerIn: parent`, separating the left and right components into their own absolutely positioned bounds (`anchors.left: parent.left`, `anchors.right: parent.right`).

## 5. Shell Commands

- Use the centralized `Quickshell.Io.Process` component for shell interactions.
- For standard CLI apps: `shellCommand.run(["alacritty", "-e", "appname"])`
- For floating windows, inject via Hyprland dispatcher: `shellCommand.run(["hyprctl", "dispatch", "exec", "[float] appname"])`
