import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/services"

/**
 * External control surface. Call from a keybind, e.g. in niri:
 *
 *   binds {
 *     Mod+Space       { spawn "qs" "-c" "chrome" "ipc" "call" "shell" "launcher"; }
 *     Mod+N           { spawn "qs" "-c" "chrome" "ipc" "call" "shell" "notifications"; }
 *     XF86AudioRaiseVolume { spawn "qs" "-c" "chrome" "ipc" "call" "shell" "volumeUp"; }
 *   }
 *
 * List everything with:  qs -c chrome ipc show
 */
Scope {
    // Panels / overlays
    IpcHandler {
        target: "shell"

        function launcher(): void { ShellState.activeScreen = null; ShellState.toggleLauncher(); }
        function quickSettings(): void { ShellState.activeScreen = null; ShellState.toggleQuickSettings(); }
        function notifications(): void { ShellState.activeScreen = null; ShellState.toggleNotifications(); }
        function calendar(): void { ShellState.activeScreen = null; ShellState.toggleCalendar(); }
        function close(): void { ShellState.closeAll(); }

        function dnd(): void { Notifications.doNotDisturb = !Notifications.doNotDisturb; }
        function nightLight(): void { Nightlight.toggle(); }
        function settings(): void { ShellState.activeScreen = null; ShellState.toggleSettings(); }
        function clipboard(): void { ShellState.activeScreen = null; ShellState.toggleClipboard(); }
        function power(): void { ShellState.activeScreen = null; ShellState.togglePowerMenu(); }
        function lock(): void { ShellState.closeAll(); Power.lock(); }

        function screenshot(): void { ShellState.closeAll(); Screenshot.capture("region-file"); }
        function screenshotFull(): void { ShellState.closeAll(); Screenshot.capture("full-file"); }

        function recordRegion(): void { ShellState.closeAll(); Recording.start(true); }
        function recordScreen(): void { ShellState.closeAll(); Recording.start(false); }
        function recordStop(): void { Recording.stop(); }
    }

    // Audio
    IpcHandler {
        target: "audio"

        function up(): void { Audio.setVolume(Audio.volume + 0.05); }
        function down(): void { Audio.setVolume(Audio.volume - 0.05); }
        function mute(): void { Audio.toggleMute(); }
        function micMute(): void { Audio.toggleMicMute(); }
        function set(pct: int): void { Audio.setVolume(pct / 100); }
    }

    // Brightness
    IpcHandler {
        target: "brightness"

        function up(): void { Brightness.set(Brightness.fraction + 0.05); }
        function down(): void { Brightness.set(Brightness.fraction - 0.05); }
        function set(pct: int): void { Brightness.set(pct / 100); }
    }
}
