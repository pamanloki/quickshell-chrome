pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Chrome OS inspired theme, driven by a Base16 palette.
 *
 * The base00..base0F slots are loaded live from a Base16 colors file (by
 * default the same `~/.config/waybar/colors.css` that Flavours generates), so
 * running `flavours apply <scheme>` re-themes the whole shell instantly. If the
 * file is missing, the built-in "Default Dark" palette below is used.
 *
 * Every semantic token (accent, surface, text, …) is derived from the Base16
 * slots, so components never touch raw hex.
 */
Singleton {
    id: root

    // ── Base16 palette (defaults = Base16 "Default Dark") ───────────────────
    property color base00: "#181818"   // background
    property color base01: "#282828"   // lighter background (pills)
    property color base02: "#383838"   // selection / high surface
    property color base03: "#585858"   // comments / faint
    property color base04: "#b8b8b8"   // dim foreground
    property color base05: "#d8d8d8"   // default foreground
    property color base06: "#e8e8e8"
    property color base07: "#f8f8f8"
    property color base08: "#ab4642"   // red
    property color base09: "#dc9656"   // orange
    property color base0A: "#f7ca88"   // yellow
    property color base0B: "#a1b56c"   // green
    property color base0C: "#86c1b9"   // cyan
    property color base0D: "#7cafc2"   // blue  ← accent
    property color base0E: "#ba8baf"   // magenta
    property color base0F: "#a16946"   // brown

    function _a(c, alpha) { return Qt.rgba(c.r, c.g, c.b, alpha); }

    // ── Accent ──────────────────────────────────────────────────────────────
    readonly property color accent:        base0D
    readonly property color accentPressed:  Qt.lighter(base0D, 1.18)
    readonly property color accentText:     base00
    readonly property color textOnAccent:   base00

    // ── Surfaces ──────────────────────────────────────────────────────────────
    readonly property color shelf:          _a(base00, 0.78)
    readonly property color surface:        base00
    readonly property color surfaceBright:  base01
    readonly property color surfaceHigh:    base02
    readonly property color surfaceGlass:   _a(base01, 0.96)
    readonly property color overlayScrim:   Qt.rgba(0, 0, 0, 0.35)

    // ── Content colors ──────────────────────────────────────────────────────
    readonly property color text:           base05
    readonly property color textDim:        base04
    readonly property color textFaint:      base03
    readonly property color outline:        _a(base05, 0.10)
    readonly property color outlineStrong:  _a(base05, 0.18)

    // ── State layers ────────────────────────────────────────────────────────
    readonly property color hover:          _a(base05, 0.08)
    readonly property color press:          _a(base05, 0.14)
    readonly property color rippleColor:    _a(base05, 0.20)

    // ── Semantic ────────────────────────────────────────────────────────────
    readonly property color good:           base0B
    readonly property color warn:           base0A
    readonly property color bad:            base08

    // ── Shape ────────────────────────────────────────────────────────────────
    readonly property int radiusSmall:  8
    readonly property int radius:       16
    readonly property int radiusLarge:  24
    readonly property int radiusPill:   999

    // ── Spacing ──────────────────────────────────────────────────────────────
    readonly property int gap:      8
    readonly property int gapLarge: 16
    readonly property int padding:  12

    // ── Shelf metrics ────────────────────────────────────────────────────────
    readonly property int shelfHeight: 64
    readonly property int iconSize:    44

    // ── Motion ───────────────────────────────────────────────────────────────
    readonly property int durFast:   110
    readonly property int durNormal: 200
    readonly property int durSlow:   300
    readonly property var  easeStandard:    [0.2, 0.0, 0, 1.0, 1, 1]
    readonly property var  easeEmphasized:  [0.05, 0.7, 0.1, 1.0, 1, 1]

    // ── Typography ───────────────────────────────────────────────────────────
    readonly property string fontFamily: "Roboto"                    // UI text
    readonly property string iconFamily: "Material Symbols Rounded"  // icon glyphs
    readonly property int fontSmall:  12
    readonly property int fontBody:   14
    readonly property int fontTitle:  16
    readonly property int fontLarge:  22

    // ── Base16 loading ────────────────────────────────────────────────────────
    readonly property string colorsPath:
        Quickshell.env("QUICKSHELL_BASE16")
        || (Quickshell.env("HOME") + "/.config/waybar/colors.css")

    function parseColors(txt) {
        if (!txt)
            return;
        // Matches `@define-color base0D #7cafc2;` (waybar/flavours format).
        const re = /@define-color\s+(base[0-9A-Fa-f]{2})\s+(#[0-9A-Fa-f]{3,8})/g;
        let m;
        while ((m = re.exec(txt)) !== null) {
            const name = "base" + m[1].slice(4).toUpperCase();
            if (root.hasOwnProperty(name))
                root[name] = m[2];
        }
    }

    FileView {
        id: colorFile
        path: root.colorsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseColors(text())
    }
}
