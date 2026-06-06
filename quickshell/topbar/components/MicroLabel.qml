import QtQuick

import "../services" as Services

Text {
    id: root
    font.family: "JetBrains Mono"
    font.pixelSize: 9
    font.weight: Font.Bold
    color: Services.Theme.muted
    opacity: 0.8
    renderType: Text.NativeRendering
}
