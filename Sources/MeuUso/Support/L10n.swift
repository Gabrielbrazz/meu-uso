import Foundation

/// User-facing text in Brazilian Portuguese.
///
/// The translations live in `assets/Localization/pt-BR.lproj/Localizable.strings`, which the build
/// scripts copy into `Contents/Resources`. Keys are the English source strings, so anything without a
/// translation — and every `swift test` / `swift run`, where there is no table — falls back to the
/// English text. The app ships no other localization and declares pt-BR as its development region, so
/// it always shows Portuguese, whatever the Mac's language.
///
/// SwiftUI literals (`Text("Settings")`, `Button("Copy")`, `.help("…")`) resolve against
/// `Bundle.main` on their own and only need a table entry. Use `tr`/`format`/`plural` for everything
/// else: AppKit titles, notifications, error descriptions, and phrases composed in model code. Never
/// pass `bundle: .module` or `#bundle` — `Bundle.module` crashes in the packaged app (see
/// `ResourceBundle.swift`).
enum L10n {
    /// The bundle that carries `pt-BR.lproj`: the app itself, or — for the CLI helper that lives in
    /// `Contents/Helpers` — the app that contains it.
    static let bundle: Bundle = {
        if Bundle.main.path(forResource: "Localizable", ofType: "strings") != nil { return .main }
        if let appURL = Bundle.main.executableURL.flatMap(ContainingAppBundle.url(for:)),
           let app = Bundle(url: appURL),
           app.path(forResource: "Localizable", ofType: "strings") != nil {
            return app
        }
        return .main
    }()

    /// The translation of `key`, or `key` itself when there is none. Safe to call on text that is
    /// already translated or never needs translating (a provider or plan name): no entry, no change.
    static func tr(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// The translation of `key` where the Portuguese depends on the context (the deadline verb "Limit"
    /// reads "Esgota", while a "Limit" label reads "Limite"). Looked up as "<context>:<key>"; without
    /// that entry — and under tests — falls back to `tr(key)`.
    static func tr(_ key: String, context: String) -> String {
        let contextual = context + ":" + key
        let value = tr(contextual)
        return value == contextual ? tr(key) : value
    }

    /// `String(format:)` over the translated format string. Translations reorder arguments with
    /// positional specifiers (`%1$@`, `%2$@`); a literal percent sign is `%%`.
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: AppLocale.current, arguments: arguments)
    }

    /// Picks the singular key when `count` is 1 and the plural key otherwise, then formats `count`
    /// into it (`%lld`). Brazilian Portuguese uses the plural for zero ("0 dias"), like English.
    static func plural(_ count: Int, _ singular: String, _ plural: String) -> String {
        format(count == 1 ? singular : plural, count)
    }
}

/// The one locale for formatted numbers, currency, dates and lists. Meu Uso is Portuguese-only, so
/// formatting is pinned to Brazilian conventions — "US$ 1.234,56", "12,9 mil", "7 de out.", "17:30" —
/// whatever the Mac's region. Machine-facing formats (ISO 8601, provider payload parsing) keep their own
/// fixed `en_US_POSIX` locales.
enum AppLocale {
    static let current = Locale(identifier: "pt_BR")
}
