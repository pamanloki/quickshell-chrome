pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Base16 theme control via the `flavours` CLI, mirroring quickshellku's logic:
 * schemes are grouped into FAMILIES (the -dark/-light variant is picked
 * automatically), the current one is tracked, and applying rewrites the colors
 * file the Theme watches so the whole shell re-themes live.
 */
Singleton {
    id: root

    property var families: []      // unique family base names, sorted
    property var _darkOf: ({})      // family -> dark slug
    property var _lightOf: ({})     // family -> light slug
    property string current: ""     // current full slug

    readonly property string currentFamily: _baseName(current)
    readonly property string mode: _variantMode(current)   // "light" | "dark"

    function _baseName(s) {
        if (!s) return "";
        s = s.replace("-dark-", "-").replace("-light-", "-");
        s = s.replace(/-dark$/, "").replace(/-light$/, "").replace(/-dawn$/, "").replace(/-day$/, "");
        return s;
    }
    function _variantMode(s) {
        return /(-light$|-light-|-dawn$|-day$)/.test(s || "") ? "light" : "dark";
    }
    function title(fam) {
        return (fam || "").replace(/[-_]/g, " ").replace(/\b\w/g, c => c.toUpperCase());
    }

    function refresh() {
        listProc.running = true;
        curProc.running = true;
    }

    // Apply a family, preferring the current light/dark mode.
    function applyFamily(fam) {
        const mode = _variantMode(root.current);
        let target = mode === "light" ? (root._lightOf[fam] || root._darkOf[fam])
                                       : (root._darkOf[fam] || root._lightOf[fam]);
        if (!target) target = fam;
        root.current = target;
        applyProc.command = ["sh", "-c", "flavours apply \"$1\"", "sh", target];
        applyProc.running = true;
    }

    // Switch the current family between its light and dark variants.
    function toggleMode() {
        const fam = root.currentFamily;
        const want = root.mode === "dark" ? "light" : "dark";
        const target = want === "light" ? (root._lightOf[fam] || root._darkOf[fam])
                                        : (root._darkOf[fam] || root._lightOf[fam]);
        if (!target)
            return;
        root.current = target;
        applyProc.command = ["sh", "-c", "flavours apply \"$1\"", "sh", target];
        applyProc.running = true;
    }

    function random() {
        Quickshell.execDetached(["sh", "-c", "flavours random 2>/dev/null"]);
        settle.restart();
    }

    Timer { id: settle; interval: 600; onTriggered: root.refresh() }

    Process {
        id: listProc
        command: ["sh", "-c", "flavours list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const slugs = text.trim().split(/\s+/).filter(x => x.length > 0);
                const dark = ({}), light = ({}), fams = ({});
                for (const s of slugs) {
                    const b = root._baseName(s);
                    fams[b] = true;
                    if (root._variantMode(s) === "light") light[b] = s;
                    else dark[b] = s;
                }
                root._darkOf = dark;
                root._lightOf = light;
                root.families = Object.keys(fams).sort();
            }
        }
    }

    Process {
        id: curProc
        command: ["sh", "-c", "flavours current 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.current = text.trim() }
    }

    Process { id: applyProc; onExited: settle.restart() }

    Component.onCompleted: refresh()
}
