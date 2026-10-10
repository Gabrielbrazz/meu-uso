import XCTest
import AppKit
import SwiftUI
@testable import MeuUso

/// Guards the Braz design system wiring: every bundled font ships in the resource bundle, registers,
/// and answers to the PostScript name `Font.braz` / `Font.brazMono` ask for; and the core tokens resolve
/// to the system's published values in both themes.
final class BrazDesignSystemTests: XCTestCase {
    func testEveryBundledFontShipsInTheResourceBundle() {
        for name in BrazFont.fileNames {
            XCTAssertNotNil(
                Bundle.meuUsoResources.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
                "\(name).ttf missing from Resources/Fonts"
            )
        }
    }

    func testFontLicensesShipNextToTheFonts() {
        for license in ["OFL-HankenGrotesk", "OFL-GeistMono"] {
            XCTAssertNotNil(
                Bundle.meuUsoResources.url(forResource: license, withExtension: "txt", subdirectory: "Fonts"),
                "\(license).txt missing from Resources/Fonts"
            )
        }
    }

    func testRegisteredFontsResolveEveryWeightTheUIAsksFor() {
        BrazFont.registerBundledFonts()
        BrazFont.registerBundledFonts() // idempotent: the second call must not fail or double-register
        let weights: [Font.Weight] = [.regular, .medium, .semibold, .bold]
        let names = Set(weights.map(BrazFont.sansName(for:)) + weights.map(BrazFont.monoName(for:)))
        for name in names {
            let font = NSFont(name: name, size: 13)
            XCTAssertNotNil(font, "\(name) did not register")
            XCTAssertEqual(font?.fontName, name)
        }
        XCTAssertEqual(NSFont(name: "HankenGrotesk-Regular", size: 13)?.familyName, "Hanken Grotesk")
        XCTAssertEqual(NSFont(name: "GeistMono-Regular", size: 13)?.familyName, "Geist Mono")
    }

    func testWeightMappingNeverGoesAboveBold() {
        XCTAssertEqual(BrazFont.sansName(for: .light), "HankenGrotesk-Regular")
        XCTAssertEqual(BrazFont.sansName(for: .semibold), "HankenGrotesk-SemiBold")
        XCTAssertEqual(BrazFont.sansName(for: .black), "HankenGrotesk-Bold")
        XCTAssertEqual(BrazFont.monoName(for: .bold), "GeistMono-SemiBold")
    }

    func testCoreTokensMatchTheDesignSystemInBothThemes() {
        assertHex(Braz.NS.bgApp, dark: 0x09090A, light: 0xFFFFFF)
        assertHex(Braz.NS.bgSurface, dark: 0x0E0E10, light: 0xFAFAFA)
        assertHex(Braz.NS.fg1, dark: 0xFAFAFA, light: 0x0A0A0B)
        assertHex(Braz.NS.accent, dark: 0x33D08A, light: 0x0E9A5E)
    }

    /// AppKit can't build a high-contrast appearance by name, so the Increase Contrast branch is
    /// exercised through the pure picker the color provider delegates to.
    func testIncreaseContrastPicksTheStrongerSwatchAndFallsBackWithoutOne() {
        let dark = BrazSwatch.white(0.06), light = BrazSwatch.black(0.06)
        let strongDark = BrazSwatch.white(0.16), strongLight = BrazSwatch.black(0.18)
        func pick(_ name: NSAppearance.Name, contrast: Bool) -> CGFloat {
            BrazSwatch.pick(for: name, dark: dark, light: light,
                            contrastDark: contrast ? strongDark : nil,
                            contrastLight: contrast ? strongLight : nil).alpha
        }
        XCTAssertEqual(pick(.darkAqua, contrast: true), 0.06)
        XCTAssertEqual(pick(.aqua, contrast: true), 0.06)
        XCTAssertEqual(pick(.accessibilityHighContrastDarkAqua, contrast: true), 0.16)
        XCTAssertEqual(pick(.accessibilityHighContrastAqua, contrast: true), 0.18)
        XCTAssertEqual(pick(.accessibilityHighContrastDarkAqua, contrast: false), 0.06)
    }

    // MARK: - Helpers

    private func assertHex(_ color: NSColor, dark: UInt32, light: UInt32,
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(hex(resolved(color, in: .darkAqua)), dark, "dark", file: file, line: line)
        XCTAssertEqual(hex(resolved(color, in: .aqua)), light, "light", file: file, line: line)
    }

    private func resolved(_ color: NSColor, in name: NSAppearance.Name) -> NSColor {
        var result = NSColor.clear
        NSAppearance(named: name)?.performAsCurrentDrawingAppearance {
            result = color.usingColorSpace(.sRGB) ?? .clear
        }
        return result
    }

    private func hex(_ color: NSColor) -> UInt32 {
        let r = UInt32((color.redComponent * 255).rounded())
        let g = UInt32((color.greenComponent * 255).rounded())
        let b = UInt32((color.blueComponent * 255).rounded())
        return (r << 16) | (g << 8) | b
    }
}
