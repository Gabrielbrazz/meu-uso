import Foundation

enum WidgetDisplayMode: String, Hashable, Sendable, CaseIterable {
    case used
    case remaining

    /// "Left" mirrors the legacy app's wording for remaining headroom. Translated, for pickers.
    var label: String {
        switch self {
        case .used: return L10n.tr("Used")
        case .remaining: return L10n.tr("Left")
        }
    }

    /// The English key that builds value phrases ("%@ used" → "95% usado"); never shown untranslated.
    var word: String {
        switch self {
        case .used: return "used"
        case .remaining: return "left"
        }
    }

    mutating func toggle() {
        self = self == .used ? .remaining : .used
    }
}
