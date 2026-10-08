import Foundation

/// Shared display formatters for live usage data: the mode-aware deadline/reset phrasing
/// (`deadlineLabel`, `resetRelativeLabel`, `resetAbsoluteLabel`), compact durations, and USD currency.
/// Phrases go through `L10n` (English keys, pt-BR table) and numbers/dates through `AppLocale`.
enum Formatters {
    /// What precedes a dollar amount: "US$" plus a no-break space, matching how the pt-BR currency
    /// formatter prints USD ("US$ 1.234,56"). Abbreviated amounts ("US$ 2,1 mil") reuse it.
    static let dollarPrefix = "US$\u{00A0}"

    static func currency(_ amount: Double, fractionDigits: Int = 2) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = AppLocale.current
        f.maximumFractionDigits = fractionDigits
        f.minimumFractionDigits = fractionDigits
        // The fallback must also respect the requested precision: a raw "\(amount)" would leak the
        // double's full decimals (e.g. "180,168"), which is exactly the rounding glitch we're fixing.
        return f.string(from: amount as NSNumber)
            ?? dollarPrefix + String(format: "%.\(fractionDigits)f", locale: AppLocale.current, amount)
    }

    /// The app's compact day/month, e.g. "21 de jun." — no year. Shared so every short calendar date
    /// (reset deadlines, the Usage Trend axis) reads the same and changes in one place.
    static func monthDayLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().locale(AppLocale.current))
    }

    /// The one mode-aware deadline phrase, shared by every "<verb> + when" label (reset countdowns,
    /// run-out projections): `.relative` → "<prefix> in 2d 6h", `.absolute` → "<prefix> today at
    /// 5:30 PM" / "<prefix> tomorrow at 9:00 AM" / "<prefix> Feb 15 at 3:45 PM" (ported from the
    /// original's `formatResetAbsoluteLabel`; time uses the 12/24-hour setting). An imminent deadline
    /// (≤5 min out relative, past-due absolute) collapses to "<prefix> soon". `prefix` is an English key
    /// ("Resets"); the whole phrase is translated ("Renova em 2d 6h", "Renova hoje às 17:30").
    static func deadlineLabel(
        _ prefix: String,
        at date: Date,
        mode: ResetDisplayMode,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        guard let when = whenLabel(at: date, mode: mode, now: now, calendar: calendar) else { return nil }
        let verb = L10n.tr(prefix)
        if when == imminent { return L10n.format("%@ soon", verb) }
        switch mode {
        case .relative: return L10n.format("%@ in %@", verb, when)
        case .absolute: return L10n.format("%@ %@", verb, when)
        }
    }

    /// The verb-less "when" phrase shared by `deadlineLabel` (which prefixes a verb) and the
    /// reset-credit tooltip (which lists bare entries): `.relative` → "2d 6h" / `imminent`;
    /// `.absolute` → "today at 5:30 PM" / "tomorrow at 9:00 AM" / "Feb 15 at 3:45 PM" / `imminent`
    /// (past-due or ≤5 min out). `nil` only when the duration is non-finite.
    static func whenLabel(
        at date: Date,
        mode: ResetDisplayMode,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        switch mode {
        case .relative:
            let seconds = date.timeIntervalSince(now)
            if seconds <= 5 * 60 { return imminent }
            return compactDuration(seconds)
        case .absolute:
            guard date.timeIntervalSince(now) > 0 else { return imminent }
            let dayDiff = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: now),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            // The wall-clock part honors the user's Auto/12h/24h time-format setting.
            let time = TimeFormatSetting.current.shortTime(date)
            if dayDiff <= 0 { return L10n.format("today at %@", time) }
            if dayDiff == 1 { return L10n.format("tomorrow at %@", time) }
            return L10n.format("%@ at %@", monthDayLabel(date), time)
        }
    }

    /// The collapsed phrase for a deadline that's past-due or within ~5 minutes — too close to print a
    /// useful countdown. Shared so `deadlineLabel` and any bare-`whenLabel` caller agree on the wording.
    static var imminent: String { L10n.tr("soon") }

    static func resetRelativeLabel(until resetsAt: Date, now: Date = Date()) -> String? {
        deadlineLabel("Resets", at: resetsAt, mode: .relative, now: now)
    }

    static func resetAbsoluteLabel(at resetsAt: Date, now: Date = Date(), calendar: Calendar = .current) -> String? {
        deadlineLabel("Resets", at: resetsAt, mode: .absolute, now: now, calendar: calendar)
    }

    /// Compact "Xd Yh" / "Xh Ym" / "Xm" duration. At the day scale it always shows two units — the
    /// hours ride along even when zero ("4d 0h") — so a span 4 days + 52 min out never reads as a flat
    /// "4d" that hides the sub-day remainder. Minutes are dropped at the day scale.
    static func compactDuration(_ seconds: TimeInterval) -> String? {
        guard seconds.isFinite, seconds > 0 else { return nil }
        let totalMinutes = max(1, Int((seconds / 60).rounded(.up)))
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return L10n.format("%lldd %lldh", days, hours)
        }
        if hours > 0 {
            return minutes > 0 ? L10n.format("%lldh %lldm", hours, minutes) : L10n.format("%lldh", hours)
        }
        return L10n.format("%lldm", minutes)
    }
}
