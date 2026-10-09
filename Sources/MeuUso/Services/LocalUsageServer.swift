import Foundation
import Network

/// Loopback-only HTTP/1.1 listener for the read-only usage API on `127.0.0.1:6737`. Starts with
/// the app; when the port is already taken the feature is silently disabled for the session
/// (matching the original app). At most 16 requests are served concurrently — beyond that a
/// connection gets `503 {"error":"server_busy"}` immediately. Web pages are kept out: no CORS
/// headers, and `LocalUsageAPI.rejection(hosts:origins:)` turns away browser requests before routing.
@MainActor
final class LocalUsageServer {
    nonisolated static let port: UInt16 = 6737
    private static let maxConcurrentConnections = 16
    private static let headLimit = 8192

    private let state: @MainActor () -> LocalUsageAPI.State
    private let queue = DispatchQueue(label: "meuuso.local-api")
    private var listener: NWListener?
    private var activeConnections = 0

    init(state: @escaping @MainActor () -> LocalUsageAPI.State) {
        self.state = state
    }

    func start() {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: "127.0.0.1",
            port: NWEndpoint.Port(rawValue: Self.port)!
        )

        let listener: NWListener
        do {
            listener = try NWListener(using: parameters)
        } catch {
            AppLog.info(.localAPI, "disabled: \(error.localizedDescription)")
            return
        }

        listener.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                // Most commonly the port is already in use — silently disable for this session.
                AppLog.info(.localAPI, "disabled: \(error.localizedDescription)")
            }
        }
        listener.newConnectionHandler = { connection in
            Task { @MainActor [weak self] in
                self?.accept(connection)
            }
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        guard activeConnections < Self.maxConcurrentConnections else {
            Self.send(LocalUsageAPI.busy, over: connection)
            return
        }
        activeConnections += 1
        receiveHead(connection, buffered: Data())
    }

    /// Reads until the end of the request head (`\r\n\r\n`). GET bodies are irrelevant, so the head
    /// is all the access check and the router need.
    private func receiveHead(_ connection: NWConnection, buffered: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Self.headLimit) { data, _, isComplete, error in
            Task { @MainActor [weak self] in
                guard let self else {
                    connection.cancel()
                    return
                }
                var buffered = buffered
                if let data {
                    buffered.append(data)
                }
                if let headEnd = buffered.range(of: Data("\r\n\r\n".utf8)) {
                    let head = String(data: buffered[..<headEnd.lowerBound], encoding: .utf8) ?? ""
                    self.finish(connection, with: self.route(head: head))
                } else if error != nil || isComplete || buffered.count >= Self.headLimit {
                    self.finish(connection, with: nil)
                } else {
                    self.receiveHead(connection, buffered: buffered)
                }
            }
        }
    }

    private func route(head: String) -> LocalUsageAPI.Response {
        let response = Self.response(to: head) { state() }
        let (method, path) = Self.parseRequestLine(head)
        // Path is secret-free (the loopback API serves only normalized usage); Debug-only. The status
        // shows when a request that may come from a web page was turned away (403).
        AppLog.debug(.localAPI, "\(method) \(path) \(response.status)")
        return response
    }

    /// The request pipeline minus the socket: turn away any request a web page could have made,
    /// then route the rest. `state` is only read for an admitted request, so a refused page never
    /// even gets usage gathered. `nonisolated` + pure so it's unit-testable without the listener.
    nonisolated static func response(
        to head: String,
        state: () -> LocalUsageAPI.State
    ) -> LocalUsageAPI.Response {
        let rejection = LocalUsageAPI.rejection(
            hosts: headerValues(named: "Host", in: head),
            origins: headerValues(named: "Origin", in: head)
        )
        if let rejection {
            return rejection
        }
        let (method, path) = parseRequestLine(head)
        return LocalUsageAPI.respond(method: method, path: path, state: state())
    }

    /// Every value of the header field `name` in the request head, in order. Names compare
    /// case-insensitively; values are trimmed. Lines split on any line break, not only CRLF, so a
    /// field tucked behind a bare LF is still seen by the access check. `nonisolated` + pure, like
    /// `parseRequestLine`.
    nonisolated static func headerValues(named name: String, in head: String) -> [String] {
        head.split(whereSeparator: \.isNewline).dropFirst().compactMap { line in
            guard let colon = line.firstIndex(of: ":"),
                  line[..<colon].trimmingCharacters(in: .whitespaces).lowercased() == name.lowercased()
            else { return nil }
            return line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
    }

    /// Parse the HTTP request line into `(method, path)`. Tolerates an empty/malformed head: a
    /// request that begins with `\r\n\r\n`, or carries invalid UTF-8 (decoded to `""` at the call
    /// site), yields no request line — which must get a normal error response rather than trap. The
    /// previous `head.split(...)[0]` force-index crashed the whole `@MainActor` menu-bar process on
    /// any such loopback payload. `nonisolated` + pure so it's unit-testable without the listener.
    nonisolated static func parseRequestLine(_ head: String) -> (method: String, path: String) {
        guard let requestLine = head.split(separator: "\r\n", maxSplits: 1).first else {
            return ("", "/")
        }
        let parts = requestLine.split(separator: " ")
        let method = parts.indices.contains(0) ? String(parts[0]) : ""
        let path = parts.indices.contains(1) ? String(parts[1]) : "/"
        return (method, path)
    }

    private func finish(_ connection: NWConnection, with response: LocalUsageAPI.Response?) {
        activeConnections -= 1
        if let response {
            Self.send(response, over: connection)
        } else {
            connection.cancel()
        }
    }

    private nonisolated static func send(_ response: LocalUsageAPI.Response, over connection: NWConnection) {
        connection.send(content: serialize(response), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    /// The response bytes. Deliberately no CORS headers: the original app sent
    /// `Access-Control-Allow-Origin: *`, which let any web page read usage through the browser.
    /// `Cross-Origin-Resource-Policy` and `nosniff` also keep the JSON from another site's
    /// `<script>`/`<img>` loads, which carry no `Origin` for the access check to see.
    /// `nonisolated` + pure so it's unit-testable.
    nonisolated static func serialize(_ response: LocalUsageAPI.Response) -> Data {
        let reason: String = switch response.status {
        case 200: "OK"
        case 403: "Forbidden"
        case 404: "Not Found"
        case 405: "Method Not Allowed"
        case 503: "Service Unavailable"
        default: "OK"
        }
        var head = "HTTP/1.1 \(response.status) \(reason)\r\n"
        head += "Cross-Origin-Resource-Policy: same-origin\r\n"
        head += "X-Content-Type-Options: nosniff\r\n"
        head += "Connection: close\r\n"
        guard let body = response.body else {
            return Data((head + "Content-Length: 0\r\n\r\n").utf8)
        }
        head += "Content-Type: application/json\r\n"
        head += "Content-Length: \(body.count)\r\n\r\n"
        return Data(head.utf8) + body
    }
}
