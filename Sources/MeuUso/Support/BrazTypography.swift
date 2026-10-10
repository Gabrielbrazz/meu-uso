import SwiftUI
import CoreText

/// Braz type: Hanken Grotesk for everything, Geist Mono for overlines, shortcuts and IDs.
///
/// Both families ship inside the resource bundle (`Resources/Fonts`, SIL Open Font License, license
/// texts alongside) as static weights — Regular, Medium, SemiBold and Bold for Hanken Grotesk; Regular,
/// Medium and SemiBold for Geist Mono. Braz never goes above 700. Fonts are registered for this process
/// only at launch (`BrazFont.registerBundledFonts()`); nothing is installed on the user's Mac.
///
/// Sizes keep the macOS scale the popover was laid out with (13pt body, 10pt captions), so adopting
/// Braz changes the face, not the layout. A glyph the fonts don't carry (arrows, math symbols) falls
/// back to the system font through CoreText's cascade.
enum BrazFont {
    /// Bundled font files (without the `.ttf` extension), each named after its PostScript name.
    static let fileNames = [
        "HankenGrotesk-Regular", "HankenGrotesk-Medium", "HankenGrotesk-SemiBold", "HankenGrotesk-Bold",
        "GeistMono-Regular", "GeistMono-Medium", "GeistMono-SemiBold"
    ]

    /// Registers the bundled fonts once per process. Safe to call repeatedly (later calls are no-ops).
    /// A missing or unreadable file is logged as an error; affected text renders in the system font.
    static func registerBundledFonts() {
        _ = registration
    }

    private static let registration: Void = {
        for name in fileNames {
            guard let url = Bundle.meuUsoResources.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
                AppLog.error(.config, "braz fonts: \(name).ttf is missing from the resource bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            guard !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else { continue }
            let failure = error?.takeRetainedValue()
            // Already registered (another code path won the race) is the state we want, not a failure.
            if let failure, CFErrorGetCode(failure) == CTFontManagerError.alreadyRegistered.rawValue {
                continue
            }
            AppLog.error(.config, "braz fonts: could not register \(name): \(failure.map { "\($0)" } ?? "unknown error")")
        }
    }()

    /// Hanken Grotesk PostScript name for a weight. Light weights read as Regular; anything heavier
    /// than Bold is clamped to Bold (Braz never uses weights above 700).
    static func sansName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light, .regular: return "HankenGrotesk-Regular"
        case .medium: return "HankenGrotesk-Medium"
        case .semibold: return "HankenGrotesk-SemiBold"
        default: return "HankenGrotesk-Bold"
        }
    }

    /// Geist Mono PostScript name for a weight. Mono tops out at SemiBold.
    static func monoName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light, .regular: return "GeistMono-Regular"
        case .medium: return "GeistMono-Medium"
        default: return "GeistMono-SemiBold"
        }
    }
}

/// The macOS text styles the popover used before Braz, at the same point sizes, so a `.caption` call
/// site keeps its size when it moves to Hanken Grotesk.
enum BrazTextStyle {
    /// Screen titles in the top bar (13pt SemiBold — Braz caps headings at 600).
    case headline
    /// Default copy (13pt).
    case body
    /// Secondary controls and fields (12pt).
    case callout
    /// Hint and empty-state copy (11pt).
    case subheadline
    /// Settings descriptions and supporting notes (10pt).
    case caption
    /// Footer metadata and small badges (10pt).
    case caption2

    var pointSize: CGFloat {
        switch self {
        case .headline, .body: return 13
        case .callout: return 12
        case .subheadline: return 11
        case .caption, .caption2: return 10
        }
    }

    var defaultWeight: Font.Weight {
        self == .headline ? .semibold : .regular
    }
}

extension Font {
    /// Hanken Grotesk at a fixed point size — the Braz replacement for `.system(size:weight:)`.
    static func braz(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(BrazFont.sansName(for: weight), fixedSize: size)
    }

    /// Hanken Grotesk at a macOS text-style size, optionally reweighted.
    static func braz(_ style: BrazTextStyle, weight: Font.Weight? = nil) -> Font {
        .braz(size: style.pointSize, weight: weight ?? style.defaultWeight)
    }

    /// Geist Mono at a fixed point size, for overlines, shortcuts and IDs.
    static func brazMono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(BrazFont.monoName(for: weight), fixedSize: size)
    }
}

extension View {
    /// Root Braz styling for a SwiftUI tree hosted by AppKit (the popover, its detail popovers, tooltips
    /// and share cards): Hanken Grotesk as the inherited font, the Braz text hierarchy behind
    /// `.primary` / `.secondary` / `.tertiary`, and Braz Green as the control tint (switches).
    func brazContentStyle() -> some View {
        font(.braz(.body))
            .foregroundStyle(Braz.fg1, Braz.fg3, Braz.fg4)
            .tint(Braz.accent)
    }

    /// Braz overline for section titles: Geist Mono, uppercase, open tracking, muted.
    func brazOverline() -> some View {
        font(.brazMono(size: 10, weight: .medium))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(Braz.fg3)
    }
}
