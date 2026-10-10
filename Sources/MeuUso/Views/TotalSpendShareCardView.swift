import SwiftUI

/// The branded, off-screen PNG for the Total Spend card's share action — the aggregate counterpart to
/// `ShareCardView`. Static: the metric title and period are baked into the header (no menus in an
/// image), and the body reuses `TotalSpendRingContent` so the exported ring and legend are exactly
/// what the popover shows. Same authored width, opaque tray background, forced appearance, and
/// watermark footer as the per-provider card, so shared images read as one family.
struct TotalSpendShareCardView: View {
    let total: TotalSpend
    let metric: TotalSpendMetric
    let appearance: ColorScheme

    private var projection: TotalSpendProjection {
        total.projection(for: metric)
    }

    var body: some View {
        ShareCardChrome(appearance: appearance) {
            headerRow
            DashboardMetricCard {
                TotalSpendRingContent(projection: projection)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(metric.title)
                .font(.braz(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            // The raw value is the English period name ("Last 30 Days"), a lookup key; show its translation.
            Text(L10n.tr(total.period.rawValue))
                .font(.braz(size: 12))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}
