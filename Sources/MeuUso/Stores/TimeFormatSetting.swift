import Foundation

/// How wall-clock times read (the absolute reset labels): the system's 12/24-hour convention, or
/// an explicit override — matching the original app's Auto/12h/24h setting.
enum TimeFormatSetting: String, Hashable, Sendable, CaseIterable, UserDefaultsBacked {
    case auto
    case twelveHour = "12h"
    case twentyFourHour = "24h"

    static let key = "timeFormat"
    static var fallback: TimeFormatSetting { .auto }

    // `current` (the user's current choice, read live) comes from `UserDefaultsBacked`.

    var label: String {
        switch self {
        case .auto: return L10n.tr("Auto")
        case .twelveHour: return L10n.tr("12-hour")
        case .twentyFourHour: return L10n.tr("24-hour")
        }
    }

    /// Short time string ("17:30" / "5:30 PM") honoring the override, via the locale's hour cycle.
    /// Auto follows the app's Brazilian locale (24-hour).
    func shortTime(_ date: Date, base: Locale = AppLocale.current) -> String {
        var components = Locale.Components(locale: base)
        switch self {
        case .auto:
            break
        case .twelveHour:
            components.hourCycle = .oneToTwelve
        case .twentyFourHour:
            components.hourCycle = .zeroToTwentyThree
        }
        return date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened, locale: Locale(components: components))
        )
    }
}
