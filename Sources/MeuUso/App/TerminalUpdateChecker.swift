import Foundation

/// Update check for the terminal release (`MeuUsoDistribution` = `terminal` in Info.plist), which ships
/// no Sparkle feed. It asks GitHub for the newest published release — `/releases/latest` skips drafts
/// and pre-releases — and reports its version when it's newer than the running one. Installing stays
/// with `meu-uso update` (the bundled `script/install.sh`); the app only surfaces the banner.
///
/// The request is a plain unauthenticated GET of public release metadata: no usage data, accounts or
/// identifiers. See `docs/privacy.md`.
struct TerminalUpdateChecker: Sendable {
    static let latestReleaseURL = URL(string: "https://api.github.com/repos/Gabrielbrazz/meu-uso/releases/latest")!

    var client: any HTTPClient = URLSessionHTTPClient()

    /// The newest release's version without the leading "v" (e.g. "0.2.0"), or `nil` when nothing is
    /// published yet (GitHub answers 404). Any other non-200 answer or an unreadable body throws.
    func latestVersion(userAgentVersion: String) async throws -> String? {
        let response = try await client.send(HTTPRequest(
            method: "GET",
            url: Self.latestReleaseURL,
            headers: [
                "Accept": "application/vnd.github+json",
                // GitHub rejects API requests without a User-Agent.
                "User-Agent": "MeuUso/\(userAgentVersion)"
            ]
        ))
        if response.statusCode == 404 { return nil }
        guard response.statusCode == 200 else {
            throw TerminalUpdateCheckError.unexpectedStatus(response.statusCode)
        }
        guard let release = try? JSONDecoder().decode(LatestRelease.self, from: response.body),
              !release.tagName.isEmpty
        else {
            throw TerminalUpdateCheckError.unreadableRelease
        }
        return Self.normalized(release.tagName)
    }

    /// True when `candidate` is a later version than `current`. Compares the dotted numbers; on a tie a
    /// final release beats a pre-release of the same number ("0.2.0" > "0.2.0-beta.1"), and two
    /// pre-releases of the same number are treated as equal (the latest-release API never offers one).
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let (candidateNumbers, candidateIsPrerelease) = parse(candidate)
        let (currentNumbers, currentIsPrerelease) = parse(current)
        let length = max(candidateNumbers.count, currentNumbers.count)
        for index in 0..<length {
            let lhs = index < candidateNumbers.count ? candidateNumbers[index] : 0
            let rhs = index < currentNumbers.count ? currentNumbers[index] : 0
            if lhs != rhs { return lhs > rhs }
        }
        return currentIsPrerelease && !candidateIsPrerelease
    }

    static func normalized(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    private static func parse(_ version: String) -> (numbers: [Int], isPrerelease: Bool) {
        let normalized = normalized(version)
        let parts = normalized.split(separator: "-", maxSplits: 1)
        let numbers = (parts.first ?? "").split(separator: ".").map { Int($0) ?? 0 }
        return (numbers, parts.count > 1)
    }

    private struct LatestRelease: Decodable {
        let tagName: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
        }
    }
}

enum TerminalUpdateCheckError: Error, LocalizedError {
    case unexpectedStatus(Int)
    case unreadableRelease

    // Log-only: the check never shows an error to the user (the banner simply doesn't appear).
    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status): return "GitHub answered \(status)"
        case .unreadableRelease: return "GitHub's latest-release answer had no tag"
        }
    }
}
