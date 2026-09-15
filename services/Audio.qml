pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

/**
 * Thin wrapper around Pipewire's default sink and source so the UI can bind to
 * volume / mute and set them without repeating the PwObjectTracker boilerplate.
 */
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // All output devices (for the audio-output picker).
    readonly property var sinks: {
        const ns = Pipewire.nodes?.values ?? [];
        const out = [];
        for (const n of ns)
            if (n && n.isSink && !n.isStream)
                out.push(n);
        return out;
    }
    function nodeLabel(n) {
        return n ? (n.description || n.nickname || n.name || "Output") : "";
    }
    function setDefaultSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    // Playback application streams (for the per-app mixer).
    readonly property var streams: {
        const ns = Pipewire.nodes?.values ?? [];
        const out = [];
        for (const n of ns)
            if (n && n.isStream && n.audio && !n.isSink)
                out.push(n);
        return out;
    }
    function streamLabel(n) {
        return n ? (n.description || n.name || "App") : "";
    }
    function setStreamVolume(n, v) {
        if (n && n.audio)
            n.audio.volume = Math.max(0, Math.min(1, v));
    }

    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? true

    function setVolume(v) {
        if (!sink?.ready || !sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // Material Symbols speaker-icon ligature by level.
    readonly property string icon: {
        if (muted || volume <= 0.001)
            return "volume_off";
        if (volume < 0.34)
            return "volume_mute";
        if (volume < 0.67)
            return "volume_down";
        return "volume_up";
    }

    // Keep the default sink / source alive & tracked so their audio binds work.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
    // Track all output devices so their labels are available in the picker.
    PwObjectTracker {
        objects: root.sinks
    }
    // Track playback streams for the per-app mixer.
    PwObjectTracker {
        objects: root.streams
    }
}
