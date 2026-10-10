import SwiftUI
import AppKit

/// Central palette + surface styles, built on the Braz design system tokens (`Braz`). Surfaces stay
/// adaptive (light/dark), with Braz's dark theme as the reference.
///
/// By default the popover is a solid, opaque panel; the opt-in Increase Transparency mode (and the
/// secret-code egg) make it translucent. Either way, Liquid Glass is reserved for the footer/top-bar
/// chrome — the controls/navigation layer — and never the data cards: Apple's guidance is to keep
/// Liquid Glass out of the content layer and back content with standard materials instead. The data
/// region follows Braz: a near-black page ("tray", `--bg-app`) with cards one step up (`--bg-surface`)
/// fenced by a 1px translucent hairline (`--border-subtle`) instead of a shadow, at the 12pt card radius.
/// Under the translucent treatment the cards drop to a stable translucent base so text stays legible
/// (see `cardSurface`).
enum Theme {
    /// Hierarchical secondary tint for the provider marks — Braz `--fg-3`, the default icon color, via
    /// the hierarchy `brazContentStyle()` installs at each root.
    static let iconGray = AnyShapeStyle(.secondary)

    /// Meter fill for a severity band — the Braz status colors: Braz Green while usage is on track
    /// (`--success`, also the primary chart series), amber when it's projected to land in the last 10%
    /// (`--warning`), red when it's projected to run out (`--danger`). Full strength: on the opaque
    /// surface there's no glass to temper against.
    static func meterFill(_ severity: WidgetData.MeterSeverity) -> AnyShapeStyle {
        AnyShapeStyle(meterColor(severity))
    }

    private static func meterColor(_ severity: WidgetData.MeterSeverity) -> Color {
        switch severity {
        case .normal: return Braz.success
        case .warning: return Braz.warning
        case .critical: return Braz.danger
        }
    }

    /// The empty part of a meter and other quiet fills (hover chips, timeline rails) — Braz
    /// `--bg-active`, a translucent neutral that sits one step above the card in both themes.
    static let meterTrack = AnyShapeStyle(Braz.bgActive)

    /// Inline notice/alert tint (refresh warning triangle, pin-limit notice, settings errors) — Braz
    /// `--warning` amber, matching the warning meter fill.
    static let notice = AnyShapeStyle(Braz.warning)

    /// Inline success tint (the "screenshot copied to clipboard" confirmation) — Braz Green, the
    /// positive counterpart to `notice`'s amber.
    static let positive = AnyShapeStyle(Braz.success)

    // MARK: - Surfaces

    /// The popover's opaque backdrop ("tray") behind the cards — Braz `--bg-app` (#09090A in dark,
    /// white in light; it does not pick up desktop wallpaper tint). Exposed as an `NSColor` so the
    /// panel's AppKit backdrop (`StatusItemController`) and the SwiftUI surface
    /// (`DashboardView.PopoverSurface`) are one color. The footer's frosted glass bar samples this opaque
    /// tray (in-window), so it reads as glass chrome over solid content, never a hole to the desktop.
    /// The cards sit on it (see `cardSurface`).
    static let trayNSColor: NSColor = Braz.NS.bgApp
    static var traySurface: Color { Color(nsColor: trayNSColor) }

    /// The opaque card surface — Braz `--bg-surface`, one step up from the tray (#0E0E10 over #09090A in
    /// dark, #FAFAFA over white in light). Opaque, so a lifted drag preview stays solid while it floats.
    static let cardNSColor: NSColor = Braz.NS.bgSurface
    static var cardFill: Color { Color(nsColor: cardNSColor) }

    /// The single corner radius for every metric/settings card surface and its lifted twin, so the
    /// floating drag preview always matches the live card's shape (Braz `--radius-lg`).
    static let cardCornerRadius: CGFloat = Braz.Radius.lg

    /// The rounded rectangle shared by every card surface (live and lifted), so the shape is defined once.
    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }
}

extension View {
    /// The card surface used for provider/settings cards, in the shared rounded shape: Braz
    /// `--bg-surface` fenced by a 1px `--border-subtle` hairline — the border does the work a shadow
    /// would, in both light and dark. The opaque surface keeps a lifted drag preview solid while it
    /// floats; the preview's depth comes from `ReorderLiftPreview`'s shadow, not a different card surface.
    func cardSurface() -> some View {
        modifier(CardSurfaceModifier())
    }

    /// A single-row lifted preview surface: the card surface with the stronger `--border-default`
    /// hairline, which fences a free-floating one-row chip off from the rows beneath it (the multi-row
    /// provider previews keep the card's subtle hairline — their shadow alone reads as detached).
    func liftedRowSurface() -> some View {
        cardSurface()
            .overlay { Theme.cardShape.strokeBorder(Braz.borderDefault, lineWidth: 1) }
    }

    /// The trailing on/off switch styling shared by every settings + Customize row toggle: no inline
    /// label (the row's leading text is the label), the native switch style, small control size. The
    /// "on" state takes Braz Green from the `.tint` that `brazContentStyle()` installs.
    func settingsSwitchStyle() -> some View {
        labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
    }
}

/// Backs `cardSurface`. The Braz card: the opaque `--bg-surface` fill with a 1px `--border-subtle`
/// hairline, in both light and dark. Live cards and drag previews share the same surface.
///
/// Under the translucent surface treatment (Increase Transparency / the secret-code egg) the opaque base
/// is dropped to a stable translucent one so the behind-window vibrancy backdrop shows through, while the
/// hairline stays so cards still read as boxes over the desktop.
private struct CardSurfaceModifier: ViewModifier {
    @Environment(\.popoverSurfaceTreatment) private var treatment

    func body(content: Content) -> some View {
        content.background {
            switch treatment {
            case .opaque:
                Theme.cardShape
                    .fill(Theme.cardFill)
                    .overlay { Theme.cardShape.strokeBorder(Braz.borderSubtle, lineWidth: 1) }
            case .translucent:
                // The AppKit backdrop already applies the system blur. A stable translucent surface here
                // keeps text legible without stacking another live material pass under every card.
                Theme.cardShape
                    .fill(Theme.cardFill.opacity(0.62))
                    .overlay { Theme.cardShape.strokeBorder(Braz.borderSubtle, lineWidth: 1) }
            }
        }
    }
}
