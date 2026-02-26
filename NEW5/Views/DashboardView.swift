//
//  DashboardView.swift
//  NEW5
//
//  Daily summary, weekly and monthly charts for glucose, sugar, meals, medications.
//


import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRange: InsightRange = .week

    private var controller: HealthLogController { HealthLogController(modelContext: modelContext) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                rangeSelector
                glucoseChartCard
                discoveredPatternsSection
                sugarSummaryCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Insights")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "0d1b2a"))
            Spacer()
            Text(dateRangeString)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1a7fc1"))
        }
        .padding(.top, 8)
    }

    private var dateRangeString: String {
        let cal = Calendar.current
        let end = Date()
        let start: Date
        switch selectedRange {
        case .day:
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: end)
        case .week:
            start = cal.date(byAdding: .day, value: -6, to: end) ?? end
        case .month:
            start = cal.date(byAdding: .day, value: -29, to: end) ?? end
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: start)) - \(cal.component(.day, from: end))"
    }

    // MARK: - Range Selector

    private var rangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(InsightRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedRange = range }
                } label: {
                    Text(range.label)
                        .font(.system(size: 14, weight: selectedRange == range ? .semibold : .medium))
                        .foregroundStyle(selectedRange == range ? Color(hex: "0d1b2a") : Color(hex: "94a3b8"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedRange == range ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(Color(hex: "e2e8f0"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Glucose Chart Card

    private var glucoseChartCard: some View {
        GlucoseChartCard(controller: controller, range: selectedRange)
    }

    // MARK: - Discovered Patterns

    private var discoveredPatternsSection: some View {
        PatternsSection(controller: controller, range: selectedRange)
    }

    // MARK: - Sugar Summary Card

    private var sugarSummaryCard: some View {
        SugarSummaryCard(controller: controller, range: selectedRange)
    }
}

// MARK: - InsightRange

enum InsightRange: CaseIterable {
    case day, week, month
    var label: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}

// MARK: - Glucose Chart Card

private struct GlucoseChartCard: View {
    let controller: HealthLogController
    let range: InsightRange

    @State private var entries: [HealthLogEntry] = []

    private let targetLow: Double = 70
    private let targetHigh: Double = 180

    private var avgGlucose: Double? {
        let vals = entries.compactMap(\.value)
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blood Glucose")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                    Text("\(range.days)-Day Overview")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                Spacer()
                if let avg = avgGlucose {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int(avg))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "22c55e"))
                        Text("mg/dL AVG")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "94a3b8"))
                    }
                }
            }

            if entries.isEmpty {
                Text("No glucose data for this period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                glucoseChart
                legendRow
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .onAppear { load() }
        .onChange(of: range) { _, _ in load() }
    }

    private var glucoseChart: some View {
        Chart {
            // Target range band
            RectangleMark(
                xStart: nil, xEnd: nil,
                yStart: .value("Low", targetLow),
                yEnd: .value("High", targetHigh)
            )
            .foregroundStyle(Color(hex: "22c55e").opacity(0.08))

            // Target range dashed borders
            RuleMark(y: .value("Target Low", targetLow))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Color(hex: "22c55e").opacity(0.4))

            RuleMark(y: .value("Target High", targetHigh))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Color(hex: "22c55e").opacity(0.4))

            // Line
            ForEach(entries) { e in
                if let v = e.value {
                    LineMark(
                        x: .value("Date", e.timestamp),
                        y: .value("mg/dL", v)
                    )
                    .foregroundStyle(Color(hex: "3b82f6"))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }

            // Colored dots
            ForEach(entries) { e in
                if let v = e.value {
                    PointMark(
                        x: .value("Date", e.timestamp),
                        y: .value("mg/dL", v)
                    )
                    .foregroundStyle(dotColor(for: v))
                    .symbolSize(50)
                }
            }
        }
        .chartYScale(domain: 60...320)
        .chartYAxis {
            AxisMarks(values: [100, 200, 300]) { val in
                AxisValueLabel {
                    if let v = val.as(Int.self) {
                        Text("\(v)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "94a3b8"))
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(hex: "e2e8f0"))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "94a3b8"))
            }
        }
        .frame(height: 200)
    }

    private var legendRow: some View {
        HStack(spacing: 20) {
            LegendDot(color: Color(hex: "22c55e"), label: "In range")
            LegendDot(color: .red, label: "High")
            LegendDot(color: .orange, label: "Low")
        }
        .padding(.top, 4)
    }

    private func dotColor(for value: Double) -> Color {
        if value < targetLow { return .orange }
        if value > targetHigh { return .red }
        return Color(hex: "22c55e")
    }

    private func load() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -range.days, to: end) ?? end
        entries = (try? controller.glucoseEntries(from: start, to: end)) ?? []
    }
}

// MARK: - Legend Dot

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "64748b"))
        }
    }
}

// MARK: - Patterns Section

private struct PatternsSection: View {
    let controller: HealthLogController
    let range: InsightRange

    @State private var entries: [HealthLogEntry] = []

    private var patterns: [(icon: String, iconColor: Color, bgColor: Color, title: String, detail: String)] {
        let glucoseEntries = entries.filter { $0.kind == HealthLogEntry.kindGlucose }
        let vals = glucoseEntries.compactMap(\.value)
        guard !vals.isEmpty else { return [] }

        var result: [(String, Color, Color, String, String)] = []

        let inRange = vals.filter { $0 >= 70 && $0 <= 180 }
        let inRangePct = Int(Double(inRange.count) / Double(vals.count) * 100)

        if inRangePct >= 80 {
            result.append(("moon.fill", Color(hex: "22c55e"), Color(hex: "22c55e").opacity(0.12),
                           "Great Overnight Control",
                           "Your glucose remained \(inRangePct)% in target range this \(range.label.lowercased())."))
        }

        let high = vals.filter { $0 > 180 }
        if !high.isEmpty {
            result.append(("sunrise.fill", .red, Color.red.opacity(0.1),
                           "Breakfast Often High",
                           "Levels spiked above target \(high.count) time\(high.count > 1 ? "s" : "") this \(range.label.lowercased())."))
        }

        let avg = vals.reduce(0, +) / Double(vals.count)
        if avg >= 70 && avg <= 140 {
            result.append(("chart.line.uptrend.xyaxis", Color(hex: "3b82f6"), Color(hex: "3b82f6").opacity(0.1),
                           "Stable Average",
                           "Your \(range.label.lowercased()) average of \(Int(avg)) mg/dL is well controlled."))
        }

        return result
    }

    var body: some View {
        if !patterns.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Discovered Patterns")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0d1b2a"))

                VStack(spacing: 10) {
                    ForEach(patterns.indices, id: \.self) { i in
                        let p = patterns[i]
                        PatternCard(icon: p.icon, iconColor: p.iconColor, bgColor: p.bgColor,
                                    title: p.title, detail: p.detail)
                    }
                }
            }
            .onAppear { load() }
            .onChange(of: range) { _, _ in load() }
        }
    }

    private func load() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -range.days, to: end) ?? end
        entries = (try? controller.entries(from: start, to: end)) ?? []
    }
}

private struct PatternCard: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(bgColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "64748b"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Sugar Summary Card

private struct SugarSummaryCard: View {
    let controller: HealthLogController
    let range: InsightRange

    @State private var entries: [HealthLogEntry] = []

    private let dailyLimit: Double = 25

    private var totalSugar: Double {
        let sugar = entries.filter { $0.kind == HealthLogEntry.kindSugar }.compactMap(\.value).reduce(0, +)
        let meal  = entries.filter { $0.kind == HealthLogEntry.kindMeal  }.compactMap(\.value).reduce(0, +)
        return sugar + meal
    }

    private var avgDailySugar: Double {
        guard range.days > 0 else { return totalSugar }
        return totalSugar / Double(range.days)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sugar Intake")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                    Text("Daily average vs limit")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.1fg", avgDailySugar))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(avgDailySugar > dailyLimit ? .red : Color(hex: "22c55e"))
                    Text("/ day avg")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Avg daily")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "64748b"))
                    Spacer()
                    Text(String(format: "%.0f / %.0f g", avgDailySugar, dailyLimit))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(avgDailySugar > dailyLimit ? .red : Color(hex: "1a7fc1"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "e2e8f0"))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(avgDailySugar > dailyLimit ? Color.red : Color(hex: "1a7fc1"))
                            .frame(width: geo.size.width * min(1, avgDailySugar / dailyLimit), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Mini stats row
            HStack(spacing: 0) {
                StatCell(label: "Total", value: String(format: "%.0fg", totalSugar))
                Divider().frame(height: 32)
                StatCell(label: "Days tracked", value: "\(range.days)")
                Divider().frame(height: 32)
                StatCell(label: "Limit", value: "\(Int(dailyLimit))g/day")
            }
            .background(Color(hex: "f8fafc"))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Watch alert trigger on load
            let _ = SugarAlertManager.shared.evaluate(totalSugar: avgDailySugar, dailyLimit: dailyLimit)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .onAppear { load() }
        .onChange(of: range) { _, _ in load() }
    }

    private func load() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -range.days, to: end) ?? end
        entries = (try? controller.entries(from: start, to: end)) ?? []
    }
}

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "0d1b2a"))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "94a3b8"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - ChartRange kept for compatibility
enum ChartRange {
    case week
    case month
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}

