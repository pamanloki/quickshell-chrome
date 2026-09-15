pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

/**
 * Active MPRIS media player (for the Now Playing card). Prefers a playing
 * player, else the first available one.
 */
Singleton {
    id: root

    readonly property var players: Mpris.players?.values ?? []

    readonly property var active: {
        const ps = root.players;
        if (ps.length === 0)
            return null;
        for (const p of ps)
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        return ps[0];
    }

    readonly property bool has: active !== null
    readonly property bool playing: active?.playbackState === MprisPlaybackState.Playing
    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""

    readonly property real length: active?.length ?? 0
    property real position: 0
    readonly property real fraction: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function playPause() { if (active && active.canTogglePlaying) active.togglePlaying(); }
    function next() { if (active && active.canGoNext) active.next(); }
    function previous() { if (active && active.canGoPrevious) active.previous(); }
    function seek(frac) {
        if (active && active.canSeek && length > 0)
            active.position = Math.max(0, Math.min(1, frac)) * length;
    }

    // Keep the scrubber live while something is playing.
    Timer {
        running: root.has
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.position = root.active ? (root.active.position ?? 0) : 0
    }
}
