import XCTest
@testable import MeuUso

/// Regression tests for keeping web pages out of the local API ("CORS e privacidade" in
/// docs/local-http-api.md). The original app answered every request with
/// `Access-Control-Allow-Origin: *`, so any page open in the browser could `fetch` usage, spend,
/// plans and account names, which can be emails. Requests go in as raw heads, the way the listener
/// hands them over: the lines before the blank line.
final class LocalUsageAccessTests: XCTestCase {
    private func makeState() -> LocalUsageAPI.State {
        LocalUsageAPI.State(
            enabledOrderedIDs: ["claude"],
            knownIDs: ["claude"],
            snapshots: ["claude": ProviderSnapshot(
                providerID: "claude",
                displayName: "Claude: braz@example.com",
                plan: "Max",
                lines: [.progress(label: "Session", used: 42, limit: 100, format: .percent)],
                refreshedAt: Date()
            )]
        )
    }

    private func respond(_ lines: [String]) -> LocalUsageAPI.Response {
        LocalUsageServer.response(to: lines.joined(separator: "\r\n")) { makeState() }
    }

    private func errorCode(_ response: LocalUsageAPI.Response) throws -> String? {
        let object = try JSONSerialization.jsonObject(with: XCTUnwrap(response.body)) as? [String: Any]
        return object?["error"] as? String
    }

    private func carriesUsage(_ response: LocalUsageAPI.Response) -> Bool {
        response.body.map { String(decoding: $0, as: UTF8.self).contains("braz@example.com") } ?? false
    }

    // MARK: - Native clients keep working

    func testCurlRequestIsServed() {
        // What `curl http://127.0.0.1:6737/v1/usage` sends.
        let response = respond([
            "GET /v1/usage HTTP/1.1",
            "Host: 127.0.0.1:6737",
            "User-Agent: curl/8.7.1",
            "Accept: */*"
        ])
        XCTAssertEqual(response.status, 200)
        XCTAssertTrue(carriesUsage(response))
    }

    func testLocalhostIsServedIgnoringCaseAndWhitespace() {
        XCTAssertEqual(respond(["GET /v1/limits HTTP/1.1", "Host: localhost:6737"]).status, 200)
        XCTAssertEqual(respond(["GET /v1/limits HTTP/1.1", "host:\tLocalHost:6737  "]).status, 200)
    }

    // MARK: - Web pages are turned away

    func testCrossOriginFetchGetsNoData() throws {
        // What `fetch("http://127.0.0.1:6737/v1/usage")` sends from a page on another site.
        let response = respond([
            "GET /v1/usage HTTP/1.1",
            "Host: 127.0.0.1:6737",
            "Origin: https://evil.example",
            "Sec-Fetch-Mode: cors",
            "Sec-Fetch-Site: cross-site"
        ])
        XCTAssertEqual(response.status, 403)
        XCTAssertEqual(try errorCode(response), "origin_not_allowed")
        XCTAssertFalse(carriesUsage(response))
    }

    func testPreflightIsRefused() throws {
        // A browser preflight always carries `Origin`, so it's refused before routing. With no
        // `Access-Control-Allow-*` in the answer, the browser never sends the real request.
        let response = respond([
            "OPTIONS /v1/usage HTTP/1.1",
            "Host: 127.0.0.1:6737",
            "Origin: https://evil.example",
            "Access-Control-Request-Method: GET",
            "Access-Control-Request-Private-Network: true"
        ])
        XCTAssertEqual(response.status, 403)
        XCTAssertEqual(try errorCode(response), "origin_not_allowed")
    }

    func testEveryOriginIsRefused() throws {
        // The API serves no pages, so no `Origin` is ours: not the loopback ones, and not `null`
        // (sandboxed iframes, `file:` pages).
        for origin in ["null", "http://127.0.0.1:6737", "http://localhost:6737", "https://evil.example"] {
            let response = respond(["GET /v1/limits HTTP/1.1", "Host: localhost:6737", "Origin: \(origin)"])
            XCTAssertEqual(response.status, 403, origin)
            XCTAssertEqual(try errorCode(response), "origin_not_allowed", origin)
        }
    }

    func testDNSRebindingIsRefused() throws {
        // A page whose own domain now resolves to 127.0.0.1 reads the API as same-origin: no `Origin`
        // and no CORS involved. Only `Host` gives it away.
        let response = respond(["GET /v1/usage HTTP/1.1", "Host: rebind.evil.example:6737"])
        XCTAssertEqual(response.status, 403)
        XCTAssertEqual(try errorCode(response), "host_not_allowed")
        XCTAssertFalse(carriesUsage(response))
    }

    func testOnlyTheExactLoopbackHostsPass() throws {
        let refused: [[String]] = [
            [],                                                  // no Host at all
            ["Host:"],
            ["Host: 127.0.0.1"],                                 // port missing
            ["Host: 127.0.0.1:6736"],                            // OpenUsage's port, not ours
            ["Host: [::1]:6737"],                                // the listener is IPv4-only
            ["Host: 0.0.0.0:6737"],
            ["Host: 127.0.0.1.evil.example:6737"],
            ["Host: 127.0.0.1:6737", "Host: evil.example:6737"]  // a repeated Host is ambiguous
        ]
        for headers in refused {
            let response = respond(["GET /v1/usage HTTP/1.1"] + headers)
            XCTAssertEqual(response.status, 403, "\(headers)")
            XCTAssertEqual(try errorCode(response), "host_not_allowed", "\(headers)")
        }
    }

    func testRefusedRequestsNeverReadUsage() {
        // The check runs before routing, so a refused page doesn't even get usage gathered.
        var stateWasRead = false
        let head = ["GET /v1/usage HTTP/1.1", "Host: 127.0.0.1:6737", "Origin: https://evil.example"]
            .joined(separator: "\r\n")
        let response = LocalUsageServer.response(to: head) {
            stateWasRead = true
            return makeState()
        }
        XCTAssertEqual(response.status, 403)
        XCTAssertFalse(stateWasRead)
    }

    // MARK: - Header parsing

    func testHeaderValuesMatchNamesIgnoringCase() {
        let head = ["GET /v1/usage HTTP/1.1", "HOST: 127.0.0.1:6737", "origin:  https://a.example ", "Origin: null"]
            .joined(separator: "\r\n")
        XCTAssertEqual(LocalUsageServer.headerValues(named: "Host", in: head), ["127.0.0.1:6737"])
        XCTAssertEqual(LocalUsageServer.headerValues(named: "Origin", in: head), ["https://a.example", "null"])
        XCTAssertEqual(LocalUsageServer.headerValues(named: "Referer", in: head), [])
    }

    func testBareLineFeedCannotHideAnOrigin() {
        // Lines split on any line break, so a field tucked behind a bare LF is still seen.
        let head = "GET /v1/usage HTTP/1.1\r\nHost: 127.0.0.1:6737\r\nX-Note: hi\nOrigin: https://evil.example"
        XCTAssertEqual(LocalUsageServer.headerValues(named: "Origin", in: head), ["https://evil.example"])
        let response = LocalUsageServer.response(to: head) { makeState() }
        XCTAssertEqual(response.status, 403)
    }

    // MARK: - Response headers

    func testResponsesCarryNoCORSHeaders() {
        let served = respond(["GET /v1/usage HTTP/1.1", "Host: 127.0.0.1:6737"])
        let refused = respond(["GET /v1/usage HTTP/1.1", "Host: 127.0.0.1:6737", "Origin: https://evil.example"])
        let empty = LocalUsageAPI.Response(status: 200, body: nil)
        for response in [served, refused, LocalUsageAPI.busy, empty] {
            let bytes = String(decoding: LocalUsageServer.serialize(response), as: UTF8.self)
            let head = bytes.components(separatedBy: "\r\n\r\n")[0].lowercased()
            XCTAssertFalse(head.contains("access-control-"), head)
            XCTAssertTrue(head.contains("cross-origin-resource-policy: same-origin"), head)
            XCTAssertTrue(head.contains("x-content-type-options: nosniff"), head)
        }
        let refusedBytes = String(decoding: LocalUsageServer.serialize(refused), as: UTF8.self)
        XCTAssertTrue(refusedBytes.hasPrefix("HTTP/1.1 403 Forbidden\r\n"), refusedBytes)
    }
}
