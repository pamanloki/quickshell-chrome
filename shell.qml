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
    Variants {
        model: Quickshell.screens
        Shelf {}
    }

    // Launcher + quick settings, created on demand per screen.
    Variants {
        model: Quickshell.screens
        OverlayHost {}
    }
}
