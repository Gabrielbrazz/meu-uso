import XCTest
@testable import MeuUso

/// The one number→text place. `.tray` is the menu-bar form (shortest), `.row` the popover form
/// (abbreviated but money keeps cents), `.full` the exact tooltip/headline form. These cases pin the
/// behavior the old `WidgetData.format`, `MenuBarContent.compactValue`, and `formatTokens` each had.
final class MetricFormatterTests: XCTestCase {
    func testDollarsAbbreviateAboveAThousandPerStyle() {
        // Tray: whole dollars under $1k (decimals round away), abbreviated above.
        XCTAssertEqual(MetricFormatter.number(42, kind: .dollars, style: .tray), "US$\u{00A0}42")
        XCTAssertEqual(MetricFormatter.number(129.81, kind: .dollars, style: .tray), "US$\u{00A0}130")
        XCTAssertEqual(MetricFormatter.number(2059.07, kind: .dollars, style: .tray), "US$\u{00A0}2,1\u{00A0}mil")
        // Row: full cents under $1k, abbreviated with one decimal above (matching token counts).
        XCTAssertEqual(MetricFormatter.number(40.76, kind: .dollars, style: .row), "US$\u{00A0}40,76")
        XCTAssertEqual(MetricFormatter.number(2059.07, kind: .dollars, style: .row), "US$\u{00A0}2,1\u{00A0}mil")
        // Full: every digit, grouped.
        XCTAssertEqual(MetricFormatter.number(2059.07, kind: .dollars, style: .full), "US$\u{00A0}2.059,07")
    }

    func testCountsAbbreviateInTrayAndRowButKeepEveryDigitInFull() {
        XCTAssertEqual(MetricFormatter.number(56_904_995, kind: .count, style: .tray), "56,9\u{00A0}mi")
        XCTAssertEqual(MetricFormatter.number(56_904_995, kind: .count, style: .row), "56,9\u{00A0}mi")
        XCTAssertEqual(MetricFormatter.number(56_904_995, kind: .count, style: .full), "56.904.995")
        XCTAssertEqual(MetricFormatter.number(1_485_201_513, kind: .count, style: .row), "1,5\u{00A0}bi")
        // Below 1,000, up to one decimal survives (a fractional credit balance).
        XCTAssertEqual(MetricFormatter.number(820.6, kind: .count, style: .row), "820,6")
    }

    func testPercentRoundsToWholeInEveryStyle() {
        XCTAssertEqual(MetricFormatter.number(95, kind: .percent, style: .full), "95%")
        XCTAssertEqual(MetricFormatter.number(95.4, kind: .percent, style: .tray), "95%")
    }

    func testPercentClampsOutOfRangeSamples() {
        // Percent is a bounded 0...100 domain: a bad sample (a provider reporting a negative or >100
        // utilization) must never print "-5%" or "130%" — it clamps to the nearest bound. (robinebers/openusage#703)
        XCTAssertEqual(MetricFormatter.number(-5, kind: .percent, style: .full), "0%")
        XCTAssertEqual(MetricFormatter.number(-5, kind: .percent, style: .tray), "0%")
        XCTAssertEqual(MetricFormatter.number(130, kind: .percent, style: .full), "100%")
        XCTAssertEqual(MetricFormatter.number(100.6, kind: .percent, style: .row), "100%")
    }

    func testValueStringAppendsUnitLabelWhenPresent() {
        let credits = MetricValue(number: 772, kind: .count, label: "credits")
        XCTAssertEqual(MetricFormatter.string(for: credits, style: .row), "772 credits")
        XCTAssertEqual(MetricFormatter.string(for: credits, style: .full), "772 credits")
        // Tokens carry no label, so nothing is appended in any style.
        let tokens = MetricValue(number: 56_904_995, kind: .count)
        XCTAssertEqual(MetricFormatter.string(for: tokens, style: .row), "56,9\u{00A0}mi")
        XCTAssertEqual(MetricFormatter.string(for: tokens, style: .full), "56.904.995")
    }

    func testCostPerMtokAppendsUnitToDollarFormatting() {
        XCTAssertEqual(MetricFormatter.costPerMtok(32, style: .tray), "US$\u{00A0}32/MTok")
        XCTAssertEqual(MetricFormatter.costPerMtok(32.1, style: .row), "US$\u{00A0}32,10/MTok")
        XCTAssertEqual(MetricFormatter.costPerMtok(32.1, style: .full), "US$\u{00A0}32,10/MTok")
        XCTAssertEqual(MetricFormatter.costPerMtok(2059.07, style: .tray), "US$\u{00A0}2,1\u{00A0}mil/MTok")
        XCTAssertEqual(MetricFormatter.costPerMtok(2059.07, style: .full), "US$\u{00A0}2.059,07/MTok")
    }

    func testTotalSpendRingCenterSplitsValueAndUnit() {
        let cases: [(value: Double, metric: TotalSpendMetric, primary: String, unit: String)] = [
            (533, .cost, "US$\u{00A0}533", "dollars"),
            (2059.07, .cost, "US$\u{00A0}2,1\u{00A0}mil", "dollars"),
            (12_400_000, .tokens, "12,4", "million"),
            (1_500_000_000, .tokens, "1,5", "billion"),
            (820.6, .tokens, "820,6", "tokens"),
            (1.37, .costPerMtok, "US$\u{00A0}1,37", "MTok")
        ]

        for testCase in cases {
            XCTAssertEqual(
                MetricFormatter.totalSpendRingCenter(testCase.value, metric: testCase.metric),
                .init(primary: testCase.primary, unit: testCase.unit)
            )
        }
    }
}
