import XCTest
@testable import MeuUso

/// The terminal release's update check: reading GitHub's latest-release answer and deciding whether it
/// is newer than the running version.
final class TerminalUpdateCheckerTests: XCTestCase {
    private func response(_ status: Int, _ body: String = "") -> HTTPResponse {
        HTTPResponse(statusCode: status, headers: [:], body: Data(body.utf8))
    }

    func testReadsTheLatestTagWithoutItsLeadingV() async throws {
        let client = FakeHTTPClient(response: response(200, #"{"tag_name": "v0.2.0", "prerelease": false}"#))
        let version = try await TerminalUpdateChecker(client: client).latestVersion(userAgentVersion: "0.1.0")
        XCTAssertEqual(version, "0.2.0")

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.url, TerminalUpdateChecker.latestReleaseURL)
        XCTAssertEqual(request.headers["User-Agent"], "MeuUso/0.1.0")
        XCTAssertNil(request.body)
    }

    func testNoPublishedReleaseIsNotAnError() async throws {
        let client = FakeHTTPClient(response: response(404, #"{"message": "Not Found"}"#))
        let version = try await TerminalUpdateChecker(client: client).latestVersion(userAgentVersion: "0.1.0")
        XCTAssertNil(version)
    }

    func testOtherFailuresThrow() async {
        for failing in [response(403, #"{"message": "rate limited"}"#), response(200, "not json"), response(200, #"{"tag_name": ""}"#)] {
            let checker = TerminalUpdateChecker(client: FakeHTTPClient(response: failing))
            do {
                _ = try await checker.latestVersion(userAgentVersion: "0.1.0")
                XCTFail("expected a throw for status \(failing.statusCode)")
            } catch {}
        }
    }

    func testVersionComparison() {
        XCTAssertTrue(TerminalUpdateChecker.isNewer("0.2.0", than: "0.1.0"))
        XCTAssertTrue(TerminalUpdateChecker.isNewer("v0.1.10", than: "0.1.9"))
        XCTAssertTrue(TerminalUpdateChecker.isNewer("1.0", than: "0.9.9"))
        XCTAssertTrue(TerminalUpdateChecker.isNewer("0.2.0", than: "0.2.0-beta.1"))

        XCTAssertFalse(TerminalUpdateChecker.isNewer("0.1.0", than: "0.1.0"))
        XCTAssertFalse(TerminalUpdateChecker.isNewer("0.1.0", than: "0.2.0"))
        XCTAssertFalse(TerminalUpdateChecker.isNewer("0.1.0", than: "0.1.0.0"))
        XCTAssertFalse(TerminalUpdateChecker.isNewer("0.2.0-beta.1", than: "0.2.0"))
    }
}
