pragma Singleton

import Quickshell
import QtQuick

/**
 * Chrome OS inspired Material 3 theme.
 * Central place for every color, radius, duration and font used by the shell.
 */
Singleton {
    id: root

    // ── Brand / accent (Chrome OS blue) ─────────────────────────────────────
    readonly property color accent:        "#8ab4f8"   // ChromeOS/Google blue
    readonly property color accentPressed:  "#aecbfa"
    readonly property color accentText:     "#062e6f"
    readonly property color textOnAccent:   "#062e6f"

    // ── Surfaces (translucent dark, like the ChromeOS shelf & bubbles) ───────
    readonly property color shelf:          Qt.rgba(0.13, 0.14, 0.16, 0.72)
    readonly property color surface:        "#202124"   // Google Grey 900-ish
    readonly property color surfaceBright:  "#292a2d"
    readonly property color surfaceHigh:    "#35363a"
    readonly property color surfaceGlass:   Qt.rgba(0.16, 0.17, 0.19, 0.92)
    readonly property color overlayScrim:   Qt.rgba(0, 0, 0, 0.35)

    // ── Content colors ──────────────────────────────────────────────────────
    readonly property color text:           "#e8eaed"   // Google Grey 200
    readonly property color textDim:        "#9aa0a6"   // Google Grey 500
    readonly property color textFaint:      "#5f6368"
    readonly property color outline:        Qt.rgba(1, 1, 1, 0.10)
    readonly property color outlineStrong:  Qt.rgba(1, 1, 1, 0.16)

    // ── State layers (Material hover/press overlays) ────────────────────────
    readonly property color hover:          Qt.rgba(1, 1, 1, 0.08)
    readonly property color press:          Qt.rgba(1, 1, 1, 0.14)
    readonly property color rippleColor:    Qt.rgba(1, 1, 1, 0.20)

    // ── Semantic ────────────────────────────────────────────────────────────
    readonly property color good:           "#81c995"   // green
    readonly property color warn:           "#fdd663"   // yellow
    readonly property color bad:            "#f28b82"   // red

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
    readonly property int durFast:   120
    readonly property int durNormal: 220
    readonly property int durSlow:   320
    readonly property var  easeStandard:    [0.2, 0.0, 0, 1.0, 1, 1]  // Material standard
    readonly property var  easeEmphasized:  [0.05, 0.7, 0.1, 1.0, 1, 1]

    // ── Typography ───────────────────────────────────────────────────────────
    readonly property string fontFamily: "JetBrainsMono Nerd Font"  // UI text
    readonly property string iconFamily: "Material Symbols Rounded"  // icon glyphs
    readonly property int fontSmall:  12
    readonly property int fontBody:   14
    readonly property int fontTitle:  16
    readonly property int fontLarge:  22
}
