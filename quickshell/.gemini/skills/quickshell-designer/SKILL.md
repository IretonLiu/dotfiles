---
name: quickshell-designer
description: Design modern, Nordic-inspired Quickshell widgets with an "Arknights" information-as-texture aesthetic. Use when the user wants to build UI components for Wayland/X11 using QML that are both cozy and technical.
---

# Quickshell Designer

This skill helps you design and implement Quickshell widgets that merge **Nordic Minimalism** with the **Arknights technical aesthetic**.

## Design Philosophy

- **Nordic Side**: Clean lines, generous white space, soft color palettes (grays, whites, muted greens/blues), and legible typography.
- **Arknights Side**: "Information as Texture." Overlay non-functional technical data (coordinates, ID strings, version numbers) at low opacity. Use sharp angles, micro-labels, and technical borders to create a sense of "tactical depth."

## Workflow

1.  **Select a Palette**: Choose from Nordic-inspired palettes in [palettes.md](references/palettes.md).
2.  **Define Layout**: Use `PanelWindow` or `FloatingWindow` for the base. Maintain a clean, minimal core.
3.  **Apply Texture**: Add "Arknights" elements like micro-labels and technical background noise. See [arknights_qml.md](references/arknights_qml.md) for patterns.
4.  **Iterate**: Use Quickshell's hot-reload to refine the opacity and placement of aesthetic elements.

## QML Implementation Tips

- **Fonts**: Use a clean sans-serif (e.g., *Inter*, *Roboto*) for functional text and a sharp monospace (e.g., *JetBrains Mono*, *Iosevka*) for technical texture.
- **Opacity**: Aesthetic technical data should be barely visible (opacity 0.05 - 0.15). It should feel like a watermark or a texture, not content.
- **Layers**: Use `Item` or `Rectangle` to layer technical textures behind functional content.

## References

- [Color Palettes](references/palettes.md)
- [Arknights Texture Patterns](references/arknights_qml.md)
