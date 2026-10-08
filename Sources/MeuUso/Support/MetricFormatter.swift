import Foundation

/// The single place a number becomes display text. Every surface — popover rows, the menu-bar strip,
/// and hover details — formats through here, so a value can never read one way in the tray and another
/// in the popover, and there is exactly one definition of "compact" ("12,9 mil" / "3,4 mi" / "1,2 bi").
/// Numbers follow `AppLocale` (Brazilian) and unit words go through `L10n`.
///
/// This replaces the scattered number→string logic that used to live in `WidgetData.format`, the
/// menu bar's `compactValue`, and the providers' own `formatTokens` / credit-label builders.
enum MetricFormatter {
    /// Three surfaces, three needs:
    /// - `.tray` — the menu-bar strip: shortest. Whole dollars under US$ 1.000, abbreviated above; counts abbreviated.
    /// - `.row` — the popover row: abbreviated like the tray, but money keeps cents ("US$ 2,1 mil", "US$ 40,76").
    /// - `.full` — tooltips and bounded headlines: every digit, grouped ("US$ 2.059,07", "56.904.995").
    enum Style {
        case tray
        case row
        case full
    }

    /// Pinned to the app's Brazilian locale so values render identically whatever the Mac's region.
    private static let locale = AppLocale.current

    /// A bare number in the given kind and style (no unit label).
    static func number(_ value: Double, kind: MetricKind, style: Style) -> String {
        switch kind {
        case .percent:
            // Percent is a bounded 0...100 domain, so clamp defensively: a bad sample (a provider
            // reporting a negative or >100 utilization) can never print "-5%" or "105%" on any
            // surface that formats through here. Over-limit is conveyed by the meter's spent state
            // and color (see `WidgetData.meterState`), not by an out-of-range headline number.
            return "\(Int(ProviderParse.clampPercent(value).rounded()))%"
        case .dollars:
            // Tray and row abbreviate four figures and up ("US$ 1,2 mi", "US$ 2,1 mil") so neither
            // carries "US$ 2.059,07"; the full form (tooltips/headlines) always keeps grouped cents.
            if abs(value) >= 1000, style != .full {
                return Formatters.dollarPrefix
                    + value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)).locale(locale))
            }
            switch style {
            case .tray:
                // Shortest below US$ 1 mil: whole dollars ("US$ 130").
                return Formatters.dollarPrefix + value.formatted(.number.precision(.fractionLength(0)).locale(locale))
            case .row, .full:
                // Full cents below $1k; the row's token-count neighbor stays readable.
                return Formatters.currency(value, fractionDigits: 2)
            }
        case .count:
            // Tray and row abbreviate at the thousands (token counts run into the billions); the full
            // form keeps every digit for the tooltip. Below 1,000 keeps up to one decimal either way, so
            // a fractional balance (e.g. 820.6) survives.
            if style != .full, abs(value) >= 1000 {
                return value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)).locale(locale))
            }
            return value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        }
    }

    /// A value with its unit label appended, e.g. "772 créditos". Token, dollar, and percent values
    /// carry no label and render bare ("56,9 mi", "US$ 4,08", "95%") — those rows show no unit, by
    /// design. The label stays an English key in the data (the local API and lookups match on it); only
    /// the displayed word is translated.
    static func string(for value: MetricValue, style: Style) -> String {
        let text = number(value.number, kind: value.kind, style: style)
        guard let label = value.label, !label.isEmpty else { return text }
        return "\(text) \(unitWord(label, for: value.number))"
    }

    /// The displayed unit word for an English unit key ("credits" → "créditos"). Exactly one takes the
    /// singular, looked up as "<key>#one" ("credits#one" → "crédito"); without that entry — and under
    /// tests, where there is no table — the plural form is used.
    static func unitWord(_ label: String, for value: Double) -> String {
        if abs(value) == 1 {
            let singularKey = label + "#one"
            let singular = L10n.tr(singularKey)
            if singular != singularKey { return singular }
        }
        return L10n.tr(label)
    }

    /// Dollars per million tokens for legends and tooltips — dollar formatting plus a fixed `/MTok`
    /// suffix so those one-line surfaces never drift.
    static func costPerMtok(_ value: Double, style: Style) -> String {
        number(value, kind: .dollars, style: style) + "/MTok"
    }

    /// The Total Spend ring's two-line center: a short primary on top and a quiet unit underneath so
    /// Cost/MTok doesn't cram `/MTok` into the hole. Shared by the live card and the share PNG.
    struct TotalSpendRingCenter: Equatable {
        let primary: String
        let unit: String
    }

    static func totalSpendRingCenter(_ value: Double, metric: TotalSpendMetric) -> TotalSpendRingCenter {
        switch metric {
        case .cost:
            // Keep the `US$` — unit line still says "dólares" for clarity in the hole.
            return TotalSpendRingCenter(primary: number(value, kind: .dollars, style: .tray), unit: L10n.tr("dollars"))
        case .tokens:
            return tokenRingCenter(value)
        case .costPerMtok:
            // `$1.37` with two decimals under 1k; abbreviated above. Unit line is `MTok`.
            return TotalSpendRingCenter(primary: costPerMtokRingPrimary(value), unit: "MTok")
        }
    }

    /// Dollar-rate figure for the Cost/MTok hole — `US$` plus two decimals under 1k, abbreviated above.
    private static func costPerMtokRingPrimary(_ value: Double) -> String {
        if abs(value) >= 1000 {
            return Formatters.dollarPrefix
                + value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)).locale(locale))
        }
        return Formatters.currency(value, fractionDigits: 2)
    }

    /// Token totals put the magnitude word on the second line (`461,8` / `milhões`) so the hole
    /// stays short even when the total runs past a billion. Below two, the word is singular
    /// ("1,2 bilhão").
    private static func tokenRingCenter(_ value: Double) -> TotalSpendRingCenter {
        let magnitude = abs(value)
        func center(_ scaled: Double, _ unit: String) -> TotalSpendRingCenter {
            TotalSpendRingCenter(
                primary: scaled.formatted(.number.precision(.fractionLength(0...1)).locale(locale)),
                unit: unitWord(unit, for: abs(scaled) < 2 ? 1 : abs(scaled))
            )
        }
        if magnitude >= 1_000_000_000 { return center(value / 1_000_000_000, "billion") }
        if magnitude >= 1_000_000 { return center(value / 1_000_000, "million") }
        if magnitude >= 1_000 { return center(value / 1_000, "thousand") }
        return center(value, "tokens")
    }
}
