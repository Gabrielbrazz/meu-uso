import XCTest
@testable import MeuUso

@MainActor
final class ProviderMarksTests: XCTestCase {
    func testProviderVectorMarksLoadWithoutFallbacks() throws {
        // "meuuso" is the app's own mark (menu bar, privacy wordmark, share card); a missing or renamed
        // SVG would silently fall back to an SF Symbol.
        for id in ["meuuso", "claude", "codex", "cursor", "devin", "grok"] {
            let mark = try XCTUnwrap(ProviderMarks.mark(for: id), "\(id) should load a vector mark")
            XCTAssertFalse(mark.path.isEmpty, "\(id) mark must carry SVG path data")
        }
    }
}
