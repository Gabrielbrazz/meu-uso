import Foundation

/// Shared user-facing copy for the usage-error cases every provider's `UsageError` otherwise repeats
/// verbatim (transport failure, malformed response, non-2xx status). Providers whose wording
/// intentionally differs — e.g. Grok's "billing" phrasing — keep their own strings. Translated through
/// `L10n` (English keys, pt-BR table), so the English text is what tests see.
enum ProviderUsageErrorText {
    /// The request never completed (network/transport failure).
    static var connectionFailed: String { L10n.tr("Usage request failed. Check your connection.") }
    /// The response came back but could not be parsed.
    static var invalidResponse: String { L10n.tr("Usage response invalid. Try again later.") }
    /// The server returned a non-2xx status.
    static func requestFailed(statusCode: Int) -> String {
        L10n.format("Usage request failed (HTTP %lld). Try again later.", statusCode)
    }
}
