import SwiftUI
import AppKit

/// Braz design system tokens — colors, radii and motion — translated from the system's web source of
/// truth (`tokens/colors.css`, `spacing.css`, `effects.css`) into adaptive AppKit/SwiftUI values.
///
/// Braz is dark-first, monochrome, with a single green accent: near-black cool neutrals, hairline
/// translucent borders instead of shadows, and color reserved for status. Dark is the reference theme;
/// light mirrors the system's `data-theme="light"` swap. Every color is an `NSColor` dynamic provider, so
/// the AppKit backdrop (`StatusItemController`), SwiftUI views and the forced-appearance share-card
/// render all resolve the same value for the current appearance. Increase Contrast resolves to the
/// stronger border and text steps where Braz defines them.
///
/// Views read surfaces and meters through `Theme`, and everything else through `Braz.<token>`. No view
/// should carry its own hex.
enum Braz {
    // MARK: - Surfaces

    /// `--bg-app`: the page behind everything (the popover tray).
    static let bgApp = Color(nsColor: NS.bgApp)
    /// `--bg-surface`: cards on the page.
    static let bgSurface = Color(nsColor: NS.bgSurface)
    /// `--bg-overlay`: floating layers — tooltips, toasts, menus.
    static let bgOverlay = Color(nsColor: NS.bgOverlay)
    /// `--bg-hover`: the one-step neutral lift under the pointer.
    static let bgHover = Color(nsColor: NS.bgHover)
    /// `--bg-active`: selected/held states, meter tracks and quiet chips.
    static let bgActive = Color(nsColor: NS.bgActive)

    // MARK: - Borders (1px hairlines do the work shadows do elsewhere)

    static let borderSubtle = Color(nsColor: NS.borderSubtle)
    static let borderDefault = Color(nsColor: NS.borderDefault)
    static let borderStrong = Color(nsColor: NS.borderStrong)

    // MARK: - Text

    /// `--fg-1`: headings and the payload value of a row.
    static let fg1 = Color(nsColor: NS.fg1)
    /// `--fg-2`: body copy.
    static let fg2 = Color(nsColor: NS.fg2)
    /// `--fg-3`: muted/supporting copy and default icon color.
    static let fg3 = Color(nsColor: NS.fg3)
    /// `--fg-4`: disabled and inactive content.
    static let fg4 = Color(nsColor: NS.fg4)

    // MARK: - Accent and status

    /// `--accent` (Braz Green). Use at most once or twice per screen: an "on" switch, a success dot,
    /// the primary data series. Primary buttons stay monochrome, never green.
    static let accent = Color(nsColor: NS.accent)
    /// `--accent-text`: green copy on the page (links to success, "copied").
    static let accentText = Color(nsColor: NS.accentText)
    static let success = Color(nsColor: NS.accent)
    static let warning = Color(nsColor: NS.warning)
    static let danger = Color(nsColor: NS.danger)
    static let info = Color(nsColor: NS.info)
    /// `--accent-fg`: text on a solid green or red fill — near-black on the bright dark-theme fills,
    /// white on the deeper light-theme ones.
    static let onStatus = Color(nsColor: NS.onStatus)
    /// Text on a solid amber fill, which stays bright in both themes.
    static let onWarning = Color(nsColor: NS.onWarning)

    // MARK: - Radii (`--radius-*`)

    enum Radius {
        /// Keyboard keys, checkboxes.
        static let xs: CGFloat = 4
        /// Buttons, inputs, tooltips, hover chips.
        static let sm: CGFloat = 6
        /// Menu items, inline banners.
        static let md: CGFloat = 8
        /// Cards and the app panel.
        static let lg: CGFloat = 12
        /// Dialogs.
        static let xl: CGFloat = 16
    }

    // MARK: - Motion (`--dur-*`, `--ease-out`)

    /// Fast and decelerating — no bounce, no overshoot.
    enum Motion {
        /// `--ease-out` at `--dur-fast` (120ms): hover fills and highlights.
        static let hover = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.12)
        /// `--ease-out` at `--dur-base` (180ms): toggles and small state changes.
        static let toggle = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.18)
    }

    // MARK: - AppKit values

    /// The same tokens as `NSColor`, for AppKit surfaces (the panel backdrop) and opacity tests.
    enum NS {
        static let bgApp = NSColor.braz(dark: .hex(0x09090A), light: .hex(0xFFFFFF))
        static let bgSurface = NSColor.braz(dark: .hex(0x0E0E10), light: .hex(0xFAFAFA))
        static let bgOverlay = NSColor.braz(dark: .hex(0x18181B), light: .hex(0xFFFFFF))
        static let bgHover = NSColor.braz(dark: .white(0.045), light: .black(0.04))
        static let bgActive = NSColor.braz(dark: .white(0.075), light: .black(0.07))

        static let borderSubtle = NSColor.braz(
            dark: .white(0.06), light: .black(0.06),
            contrastDark: .white(0.16), contrastLight: .black(0.18)
        )
        static let borderDefault = NSColor.braz(
            dark: .white(0.09), light: .black(0.1),
            contrastDark: .white(0.22), contrastLight: .black(0.26)
        )
        static let borderStrong = NSColor.braz(
            dark: .white(0.16), light: .black(0.18),
            contrastDark: .white(0.32), contrastLight: .black(0.36)
        )

        static let fg1 = NSColor.braz(dark: .hex(0xFAFAFA), light: .hex(0x0A0A0B))
        static let fg2 = NSColor.braz(dark: .hex(0xB6B6BE), light: .hex(0x3D3D44))
        static let fg3 = NSColor.braz(
            dark: .hex(0x8B8B95), light: .hex(0x6B6B74),
            contrastDark: .hex(0xB6B6BE), contrastLight: .hex(0x3D3D44)
        )
        static let fg4 = NSColor.braz(
            dark: .hex(0x5E5E68), light: .hex(0xA0A0A8),
            contrastDark: .hex(0x8B8B95), contrastLight: .hex(0x6B6B74)
        )

        // Light swaps to the darker step of each hue so it holds contrast on white.
        static let accent = NSColor.braz(dark: .hex(0x33D08A), light: .hex(0x0E9A5E))
        static let accentText = NSColor.braz(dark: .hex(0x5FE0A3), light: .hex(0x0C7A4C))
        static let warning = NSColor.braz(dark: .hex(0xF7C04A), light: .hex(0xC7851A))
        static let danger = NSColor.braz(dark: .hex(0xFF6B6B), light: .hex(0xD23434))
        static let info = NSColor.braz(dark: .hex(0x5AA8FF), light: .hex(0x2A6FD1))
        static let onStatus = NSColor.braz(dark: .hex(0x04140C), light: .hex(0xFFFFFF))
        static let onWarning = NSColor.braz(dark: .hex(0x1A1204), light: .hex(0x1A1204))
    }
}

/// One resolved token value: an sRGB hex plus alpha.
struct BrazSwatch: Sendable {
    let hex: UInt32
    let alpha: CGFloat

    static func hex(_ value: UInt32, alpha: CGFloat = 1) -> BrazSwatch {
        BrazSwatch(hex: value, alpha: alpha)
    }

    /// Translucent white — the dark theme's overlays and hairlines.
    static func white(_ alpha: CGFloat) -> BrazSwatch { .hex(0xFFFFFF, alpha: alpha) }

    /// Translucent black — the light theme's overlays and hairlines.
    static func black(_ alpha: CGFloat) -> BrazSwatch { .hex(0x000000, alpha: alpha) }

    var nsColor: NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension NSColor {
    /// A Braz token that follows the drawing appearance: dark or light, with optional stronger values
    /// under Increase Contrast (falling back to the regular pair when a token doesn't define one).
    static func braz(
        dark: BrazSwatch,
        light: BrazSwatch,
        contrastDark: BrazSwatch? = nil,
        contrastLight: BrazSwatch? = nil
    ) -> NSColor {
        NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua
            ])
            return BrazSwatch.pick(
                for: match, dark: dark, light: light, contrastDark: contrastDark, contrastLight: contrastLight
            ).nsColor
        }
    }
}

extension BrazSwatch {
    /// The swatch for a matched appearance. Split out of the color provider because AppKit can't build
    /// a high-contrast `NSAppearance` by name (it hands back the regular one), so tests exercise the
    /// Increase Contrast branch here instead.
    static func pick(
        for match: NSAppearance.Name?,
        dark: BrazSwatch,
        light: BrazSwatch,
        contrastDark: BrazSwatch?,
        contrastLight: BrazSwatch?
    ) -> BrazSwatch {
        switch match {
        case .darkAqua: return dark
        case .accessibilityHighContrastDarkAqua: return contrastDark ?? dark
        case .accessibilityHighContrastAqua: return contrastLight ?? light
        default: return light
        }
    }
}
