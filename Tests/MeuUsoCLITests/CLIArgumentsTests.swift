import XCTest
@testable import MeuUsoCLI

final class CLIArgumentsTests: XCTestCase {
    func testParsesProviderAndForce() throws {
        let parsed = try CLIArguments.parse(["Codex", "--force"])
        XCTAssertEqual(parsed.command, .read)
        XCTAssertEqual(parsed.providerID, "codex")
        XCTAssertTrue(parsed.force)
    }

    func testRejectsUnknownOptionsAndMultipleProviders() {
        XCTAssertThrowsError(try CLIArguments.parse(["--json"]))
        XCTAssertThrowsError(try CLIArguments.parse(["claude", "codex"]))
    }

    func testParsesUpdateSubcommand() throws {
        let plain = try CLIArguments.parse(["update"])
        XCTAssertEqual(plain.command, .update)
        XCTAssertFalse(plain.force)
        XCTAssertNil(plain.providerID)

        let forced = try CLIArguments.parse(["update", "--force"])
        XCTAssertEqual(forced.command, .update)
        XCTAssertTrue(forced.force)
    }

    func testUpdateTakesNoProviderAndOnlyCountsInFirstPosition() {
        XCTAssertThrowsError(try CLIArguments.parse(["update", "codex"]))
        // After a provider, "update" is just a second provider name, which is rejected as before.
        XCTAssertThrowsError(try CLIArguments.parse(["codex", "update"]))
    }
}
