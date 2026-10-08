import Foundation

struct PricingFallbackOption: Identifiable, Sendable, Equatable {
    let id: String
    let title: String

    static func title(for model: String) -> String {
        model.split(separator: "-").map { part in
            switch part {
            case "gpt": "GPT"
            case "o1", "o3", "o4": String(part)
            default: part.prefix(1).uppercased() + part.dropFirst()
            }
        }.joined(separator: " ")
    }

    /// The displayed source note: `note` translated, plus the fallback-priced models when there are
    /// any. `note` is a provider's English key ("From your Codex logs (estimated)") or a phrase already
    /// composed in Portuguese ("Across your Macs · …"), which `L10n.tr` returns unchanged.
    static func sourceNote(_ note: String, modelsByDay: [String: Set<String>]?, days: Set<String>) -> String {
        let translatedNote = L10n.tr(note)
        let models = days.reduce(into: Set<String>()) { $0.formUnion(modelsByDay?[$1] ?? []) }
        guard !models.isEmpty else { return translatedNote }
        let names = models.sorted().map { title(for: $0) }.joined(separator: ", ")
        return L10n.format("%@ · Fallback estimates: %@", translatedNote, names)
    }
}

extension ModelPricing {
    /// Only reviewed public IDs from the supplement can enter the picker. Never derive choices
    /// from session logs or account-specific model lists, and never offer an unresolved price.
    func fallbackOptions(for providerID: String) -> [PricingFallbackOption] {
        var seen = Set<String>()
        return (supplement.fallbackModels[providerID] ?? []).compactMap { model in
            guard seen.insert(model).inserted, fallbackRates(model: model, providerID: providerID) != nil else {
                return nil
            }
            return PricingFallbackOption(id: model, title: PricingFallbackOption.title(for: model))
        }
    }

    /// Exact entries only: an estimation reference must not itself depend on a fuzzy guess.
    func fallbackRates(model: String, providerID: String) -> ModelRates? {
        guard supplement.fallbackModels[providerID]?.contains(model) == true,
              let rates = supplement.pricing[model]
                ?? primary.findExact(model)?.rates
                ?? secondary.findExact(model)?.rates,
              rates.inputPerMillion.isFinite, rates.inputPerMillion > 0,
              rates.outputPerMillion.isFinite, rates.outputPerMillion > 0,
              rates.cacheReadPerMillion.isFinite, rates.cacheReadPerMillion >= 0
        else { return nil }
        return rates
    }
}
