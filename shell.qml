//@ pragma UseQApplication

import Quickshell
import "components"

/**
 * quickshell-chrome — a Chrome OS style desktop shell for Quickshell.
 *
 * Per screen we spawn:
 *   • Shelf         — the bottom bar (launcher, apps, status area)
 *   • QuickSettings — the bottom-right system bubble
 *   • Launcher      — the fullscreen app launcher
 *
 * Run with:  qs -c chrome   (after linking this folder into ~/.config/quickshell)
 */
ShellRoot {
    // External control (keybinds): qs -c chrome ipc call shell launcher
    Ipc {}

    Variants {
        model: Quickshell.screens
        Shelf {}
    }

    // Launcher + quick settings + calendar, created on demand per screen.
    Variants {
        model: Quickshell.screens
        OverlayHost {}
    }

    // Always-present transient surfaces.
    Variants {
        model: Quickshell.screens
        Toasts {}
    }
    Variants {
        model: Quickshell.screens
        Osd {}
    }

    // Rounded display corners (ChromeOS look).
    Variants {
        model: Quickshell.screens
        ScreenCorners {}
    }
}
