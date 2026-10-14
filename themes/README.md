# Shared desktop themes

`palettes.json` is the version-controlled source of truth for the core desktop:
Quickshell, Hyprland, Alacritty, Dunst, GTK 3/4, Pi, and the GNOME system
light/dark preference.

Apply a profile manually:

```sh
~/dotfiles/scripts/theme list
~/dotfiles/scripts/theme apply dark
~/dotfiles/scripts/theme apply light
~/dotfiles/scripts/theme current
```

The renderer writes complete files atomically to
`~/.local/state/dotfiles-theme/`; generated files never modify the repository.
Hyprland imports its generated fragment and is reloaded with `hyprctl reload`.
Alacritty receives a live IPC update (and also watches its generated import).
Dunst is safely restarted with its generated full configuration. Pi's currently
selected user theme is regenerated; Pi hot
reloads active user themes. Quickshell watches `quickshell.json`, so all bars
and launcher surfaces update in place. The topbar theme control invokes the
same command.

GTK receives the matching `prefer-dark`/`prefer-light` and accent settings plus
semantic GTK CSS variables. GTK has no reliable process-wide CSS hot reload;
most applications update via the settings service, but reopen an application if
its already-open window does not redraw. Firefox follows the system
light/dark preference for website `prefers-color-scheme`; its browser chrome is
not changed without a separate Firefox theme or `userChrome.css`.

To add a palette, add a peer to `profiles.dark` in `palettes.json` with the
same semantic fields, then run `theme apply <name>`.
