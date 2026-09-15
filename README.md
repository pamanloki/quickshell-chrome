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
  - Inline **Wi-Fi** (scan + connect), **Bluetooth** (connect / disconnect),
    **Night Light** (colour-temperature slider) and **audio-output** picker
    panels — tap a pod / the speaker button to expand
  - Brightness slider (`brightnessctl`) and volume slider (PipeWire)
  - Footer with date, battery status and Settings / Lock / Power buttons
- **Notifications** — a desktop notification server with ChromeOS-style toast
  cards (bottom-right, auto-dismiss), a standalone **notification center**
  panel (its own bubble, not merged into quick settings) opened by the
  status-area bell with an unread count, and Do-Not-Disturb
- **On-screen display** — a volume / brightness OSD pill that pops on change
- **Calendar** — click the clock for a month view popup
- **Settings panel** — opened from the quick-settings gear: Base16 **theme**
  switcher (Flavours), **wallpaper** picker (swww / swaybg), **updates** check
  (xbps / Void), **About** system info, and power actions
- **Base16 theming** — the whole palette is driven by a Base16 colors file and
  live-reloads, so `flavours apply <scheme>` re-themes the shell instantly
- **System tray** — StatusNotifierItem icons with real DBus menus
- **Now Playing** — a standalone MPRIS media panel (art, transport, seek),
  opened by a music glyph in the status area that only appears while a player
  is present and vanishes when playback stops
- **Screen capture** — pod with a right-click menu: region/full × clipboard/file
- **Tote (holding space)** — a status-area tray that appears after a capture
  and clears itself a few minutes later; open, copy, or delete recent
  screenshots straight from the shelf
- **Frequent apps** — the launcher surfaces your most-used apps
- **Workspace indicator** — niri workspace pips on the shelf
- **Shelf context menu** — right-click empty shelf space to toggle auto-hide
  or jump to the wallpaper / theme / settings panes
- **Rounded display corners**, low-battery notifications, and Material 3 motion
- Multi-monitor aware — a shelf per screen; popups open on the active screen only

## Requirements

- **Quickshell** (recent build) running on Qt **6.7+**
- A **wlroots**-based Wayland compositor (uses `wlr-layer-shell`)
- Fonts (family names are set in `config/Theme.qml`; adjust if fontconfig lists
  them differently):
  - **JetBrains Mono Nerd Font** — UI text (`fontFamily`). Verify with
    `fc-list | grep -i jetbrains`.
  - **Material Symbols Rounded** — icons (`iconFamily`). Install the *variable*
    font so filled icons work (`ttf-material-symbols-variable`, or the
    `MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` from
    [fonts.google.com/icons](https://fonts.google.com/icons)), then `fc-cache -f`.
    Filled icons use the `FILL` axis, which needs Qt **6.7+**.
- Optional CLI tools (each feature degrades gracefully if missing):
  - `brightnessctl` — brightness slider
  - `nmcli` (NetworkManager) — network status, Wi-Fi list & toggle
  - `bluetoothctl` (BlueZ) — bluetooth status, device list & toggle
  - `wlsunset` (or `gammastep`) — Night Light
  - `grim` + `slurp` + `wl-clipboard` — screen capture
  - `swww` (or `swaybg`) — wallpaper setting
  - `flavours` — Base16 theme switching
  - `loginctl` / `systemctl` — power actions (lock, sleep, restart, off)
  - [`fyi`](https://codeberg.org/dnkl/fyi) — low-battery & screenshot notifications
  - `niri` — workspace indicator (auto-detected via `NIRI_SOCKET`)
  - PipeWire + WirePlumber — audio; any MPRIS player — Now Playing

Battery, audio, notifications, media (MPRIS) and the system tray come from
Quickshell's built-in services (UPower / PipeWire / NotificationServer /
Mpris / SystemTray), so no extra polling scripts are needed.

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

**Pin your own apps** straight from the shelf: **right-click** an icon for a
menu that lists every open window of that app (pick one to focus, or close it —
handy when you have several `foot` terminals), plus *New window* and *Add to
Dock* / *Remove from Dock*. The pinned list is persisted to
`$XDG_STATE_HOME/quickshell-chrome/dock_pinned.json` and starts empty.
Left-click launches a pinned app (or focuses it if already running); running
apps that aren't pinned appear after a divider with a running dot.

## IPC & keybinds

Control the shell from keybinds via Quickshell IPC:

```sh
qs -c chrome ipc call shell launcher        # toggle the launcher
qs -c chrome ipc call shell quickSettings   # toggle quick settings
qs -c chrome ipc call shell notifications   # toggle the notification center
qs -c chrome ipc call shell calendar        # toggle the calendar
qs -c chrome ipc call shell close           # close all overlays
qs -c chrome ipc call shell dnd             # toggle Do Not Disturb
qs -c chrome ipc call shell nightLight      # toggle Night Light
qs -c chrome ipc call audio up|down|mute|micMute
qs -c chrome ipc call audio set 50          # volume %
qs -c chrome ipc call brightness up|down
qs -c chrome ipc call brightness set 50     # brightness %
qs -c chrome ipc show                       # list every handler
```

A ready-made **niri** keybind block using these lives in
[`niri/binds.kdl`](niri/binds.kdl) — copy it into `~/.config/niri/config.kdl`.
Handlers are defined in `components/Ipc.qml`.

## Theming (Base16)

`config/Theme.qml` loads a Base16 palette (`base00`–`base0F`) from a colors file
and derives every semantic token from it, so switching schemes re-themes
everything live. By default it reads `~/.config/waybar/colors.css` — the same
file [Flavours](https://github.com/Misterio77/flavours) generates — matching
lines like `@define-color base0D #7cafc2;`. Point it elsewhere with the
`QUICKSHELL_BASE16` env var. If the file is missing, a built-in "Default Dark"
palette is used. `base0D` is the accent (Chrome OS blue by default).

## Project layout

```
shell.qml              # entry point — spawns a Shelf + OverlayHost per screen
config/
  Theme.qml            # design tokens (Material 3 / Chrome OS palette)
  ShellState.qml       # shared UI state (which overlay is open, dock menu)
services/
  Time.qml Audio.qml Battery.qml Brightness.qml
  Network.qml Bluetooth.qml Nightlight.qml Notifications.qml
  Apps.qml DockConfig.qml            # persisted pinned apps
components/
  Shelf.qml            # the bottom bar
  LauncherButton.qml StatusArea.qml ShelfApp.qml
  OverlayHost.qml      # lazily creates the on-demand overlays per screen
  Launcher.qml         # fullscreen app search
  QuickSettings.qml    # system bubble (pods, panels)
  NotificationCenter.qml   # standalone notification panel (status-area bell)
  TotePanel.qml        # holding-space popup (recent screenshots)
  MusicPanel.qml       # standalone Now Playing popup (status-area glyph)
  Calendar.qml         # month-view popup (click the clock)
  DockMenu.qml         # dock right-click Add/Remove from Dock
  ShelfMenu.qml        # right-click empty shelf (autohide / wallpaper / settings)
  Toasts.qml           # notification toasts
  Osd.qml              # volume / brightness on-screen display
  QsToggle.qml QsSlider.qml QsIconButton.qml
  MaterialIcon.qml StateLayer.qml   # primitives
```

## Notes / troubleshooting

- **Text shows as boxes / wrong font** → Roboto isn't installed, or is
  registered under a different family name than `config/Theme.qml` expects.
- **Icons show as boxes or the ligature text** → Material Symbols Rounded isn't
  installed (check `fc-list | grep -i "material symbols rounded"`).
- **Icons never look filled** → install the *variable* Material Symbols font and
  make sure Qt is 6.7+ (the `FILL` axis needs `font.variableAxes`).
- **Every icon is a blank tile** in the launcher → your icon theme is missing;
  set one with your DE tools or install e.g. `papirus-icon-theme`.
- **Nothing appears** → make sure your compositor supports `wlr-layer-shell`
  and that `qs` reports no QML errors in the terminal.

## License

MIT
