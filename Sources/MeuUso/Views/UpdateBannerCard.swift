import SwiftUI

/// The "Update Available" banner at the top of the dashboard. Shows while a *scheduled* check has found
/// a new version (`UpdaterController.availableUpdateVersion`).
///
/// - Sparkle release: for a menu-bar (dockless) app macOS keeps Sparkle's own alert window behind
///   everything, so the popover carries the reminder instead. The install button runs a user-initiated
///   check, which Sparkle presents frontmost (its window with release notes, download progress, and the
///   install flow).
/// - Terminal release (`updatesFromTerminal`): there is no in-app installer; the button copies the
///   `meu-uso update` command for the user to paste into Terminal, and its title confirms the copy.
///
/// The close button snoozes the banner; the next scheduled check re-surfaces the update. Same grouped
/// content card as `CustomizeHintCard` (`cardSurface`), scrolling with the sections.
struct UpdateBannerCard: View {
    @Environment(UpdaterController.self) private var updater
    /// The found update's display version, e.g. "0.8.1".
    let version: String

    @State private var copiedCommand = false

    var body: some View {
        if updater.updatesFromTerminal {
            DismissableHintCard(
                systemImage: "arrow.down.circle",
                title: "Update Available",
                message: L10n.format("Meu Uso %@ is available. Run the update command in Terminal.", version),
                buttonTitle: copiedCommand ? "Copied to clipboard" : "Copy Update Command",
                action: {
                    updater.copyTerminalUpdateCommand()
                    copiedCommand = true
                },
                onDismiss: { withAnimation(Motion.spring) { updater.dismissAvailableUpdate() } }
            )
        } else {
            DismissableHintCard(
                systemImage: "arrow.down.circle",
                title: "Update Available",
                message: L10n.format("Meu Uso %@ is ready to download.", version),
                buttonTitle: "Install Update",
                action: { updater.installAvailableUpdate() },
                onDismiss: { withAnimation(Motion.spring) { updater.dismissAvailableUpdate() } }
            )
        }
    }
}
