pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Minimal niri IPC: tracks workspaces from the JSON event-stream and can focus
 * one. Inactive (does nothing) when not running under niri.
 */
Singleton {
    id: root

    readonly property bool onNiri: (Quickshell.env("NIRI_SOCKET") || "").length > 0
    property var workspaces: []

    function _sort(list) {
        return list.slice().sort((a, b) =>
            a.output === b.output ? (a.idx - b.idx) : (a.output < b.output ? -1 : 1));
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }
    function focusUp() { Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]); }
    function focusDown() { Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]); }

    function handleEvent(ev) {
        if (ev.WorkspacesChanged) {
            root.workspaces = _sort(ev.WorkspacesChanged.workspaces.slice());
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const ws = root.workspaces.slice();
            let out = null;
            for (const w of ws)
                if (w.id === id) out = w.output;
            for (const w of ws) {
                if (w.id === id) {
                    w.is_active = true;
                    w.is_focused = ev.WorkspaceActivated.focused;
                } else {
                    if (w.output === out) w.is_active = false;
                    if (ev.WorkspaceActivated.focused) w.is_focused = false;
                }
            }
            root.workspaces = ws;
        } else if (ev.WorkspaceUrgencyChanged) {
            const ws = root.workspaces.slice();
            for (const w of ws)
                if (w.id === ev.WorkspaceUrgencyChanged.id) w.is_urgent = ev.WorkspaceUrgencyChanged.urgent;
            root.workspaces = ws;
        }
    }

    Process {
        id: stream
        running: root.onNiri
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: (line) => {
                try { root.handleEvent(JSON.parse(line)); } catch (e) {}
            }
        }
    }
}
