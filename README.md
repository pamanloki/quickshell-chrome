# quickshell-chrome

A **Chrome OS–style desktop shell** built with [Quickshell](https://quickshell.outfoxxed.me/).
It gives any wlroots-based Wayland compositor (Hyprland, Sway, niri, river, …) the
look and feel of Chrome OS: the translucent **shelf** at the bottom, the round
**launcher** button, a searchable **app launcher**, and a **quick settings**
bubble with network / bluetooth toggles and brightness / volume sliders.

![layout](docs/layout.svg)

## Features

- **Shelf** — full-width translucent bottom bar
  - Round Chrome OS launcher button (white circle + blue dot)
  - Centered pinned apps with hover pills, tooltips and running-window indicators
  - Right-hand **status area** pill (bluetooth · network · battery · clock)
- **App launcher** — bubble launcher above the launcher button
  - Instant search across all installed `.desktop` apps
  - Scrollable icon grid, `Enter` launches the top hit, `Esc` closes
- **Quick settings** — bottom-right system bubble
  - Feature pods: Network (Wi-Fi), Bluetooth, Do Not Disturb, Night Light
  - Brightness slider (`brightnessctl`) and volume slider (PipeWire)
  - Footer with date, battery status and Settings / Lock / Power buttons
- Material 3 motion — ripples, state layers, spring pop-in animations
- Multi-monitor aware — a shelf per screen; popups open on the active screen only

## Requirements

- **Quickshell** (recent build) running on Qt **6.7+**
- A **wlroots**-based Wayland compositor (uses `wlr-layer-shell`)
- Fonts:
  - **Roboto** (UI text)
  - **Material Symbols Rounded** (icons) — install the variable font, e.g.
    the `ttf-material-symbols-variable` / `material-symbols` package, or drop
    `MaterialSymbolsRounded.ttf` into `~/.local/share/fonts` and run `fc-cache -f`.
- Optional CLI tools (each feature degrades gracefully if missing):
  - `brightnessctl` — brightness slider
  - `nmcli` (NetworkManager) — network status & Wi-Fi toggle
  - `bluetoothctl` (BlueZ) — bluetooth status & toggle
  - `wlsunset` — Night Light
  - PipeWire + WirePlumber — audio

The battery, audio and system-tray data come from Quickshell's built-in
services (UPower / PipeWire), so no extra polling scripts are needed.

## Install

```sh
# 1. Clone into your Quickshell config directory
git clone https://github.com/pamanloki/quickshell-chrome \
  ~/.config/quickshell/chrome

# 2. Launch it
qs -c chrome
```

Or run it straight from a checkout without installing:

```sh
qs -p /path/to/quickshell-chrome/shell.qml
```

To start it with your session, add `qs -c chrome &` to your compositor's
autostart (e.g. Hyprland `exec-once = qs -c chrome`).

## Configuration

Everything is plain QML — edit and it hot-reloads.

| What | Where |
|------|-------|
| Colors, radii, fonts, motion | `config/Theme.qml` |
| Pinned shelf apps | `config/Pinned.qml` |
| Global open/close state | `config/State.qml` |
| System integrations | `services/*.qml` |
| Widgets | `components/*.qml` |

**Pin your own apps** by editing the `apps` list in `config/Pinned.qml`. Each
entry is a `.desktop` id (filename without `.desktop`); optional `exec` / `icon`
/ `name` act as fallbacks for apps without a desktop file:

```qml
{ id: "org.mozilla.firefox", exec: "firefox", icon: "firefox", name: "Firefox" }
```

## Project layout

```
shell.qml              # entry point — spawns a Shelf/QuickSettings/Launcher per screen
config/
  Theme.qml            # design tokens (Material 3 / Chrome OS palette)
  State.qml            # shared UI state (which overlay is open)
  Pinned.qml           # shelf app list
services/
  Time.qml Audio.qml Battery.qml
  Brightness.qml Network.qml Bluetooth.qml Apps.qml
components/
  Shelf.qml            # the bottom bar
  LauncherButton.qml StatusArea.qml ShelfApp.qml
  Launcher.qml         # fullscreen app search
  QuickSettings.qml    # system bubble
  QsToggle.qml QsSlider.qml QsIconButton.qml
  MaterialIcon.qml StateLayer.qml   # primitives
```

## Notes / troubleshooting

- **Icons show as boxes** → the Material Symbols Rounded font isn't installed.
- **Every icon is a blank tile** in the launcher → your icon theme is missing;
  set one with your DE tools or install e.g. `papirus-icon-theme`.
- **Nothing appears** → make sure your compositor supports `wlr-layer-shell`
  and that `qs` reports no QML errors in the terminal.

## License

MIT
