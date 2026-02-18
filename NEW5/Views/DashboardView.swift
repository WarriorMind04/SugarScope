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
    @State private var selectedDay = Date()
    @State private var range: ChartRange = .week

    private var controller: HealthLogController { HealthLogController(modelContext: modelContext) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Health dashboard")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

                dayPicker
                dailySummarySection
                chartsSection
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.98, blue: 0.96))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var dayPicker: some View {
        HStack {
            Text("Day")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            DatePicker("", selection: $selectedDay, displayedComponents: .date)
                .labelsHidden()
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var dailySummarySection: some View {
        DailySummaryView(controller: controller, date: selectedDay)
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Range", selection: $range) {
                Text("7 days").tag(ChartRange.week)
                Text("30 days").tag(ChartRange.month)
            }
            .pickerStyle(.segmented)

            ChartsView(controller: controller, range: range)
        }
    }
}

enum ChartRange {
    case week
    case month
}

/// WHO-style guideline: ~25 g added sugar per day for adults; often lower for people with diabetes.
private let recommendedDailySugarGrams: Double = 25

private struct DailySummaryView: View {
    let controller: HealthLogController
    let date: Date

    @State private var entries: [HealthLogEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily summary")
                .font(.headline)
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

            let glucose = entries.filter { $0.kind == HealthLogEntry.kindGlucose }
            let meals = entries.filter { $0.kind == HealthLogEntry.kindMeal }
            let sugarOnly = entries.filter { $0.kind == HealthLogEntry.kindSugar }
            let meds = entries.filter { $0.kind == HealthLogEntry.kindMedication }
            let totalSugar = sugarOnly.compactMap(\.value).reduce(0, +) + meals.compactMap(\.value).reduce(0, +)
            let totalCarbs = meals.compactMap(\.secondaryValue).reduce(0, +)
            let totalCal = meals.compactMap(\.note).compactMap { Int($0.replacingOccurrences(of: " kcal", with: "")) }.reduce(0, +)

            sugarGuidanceSection(totalSugar: totalSugar)

            HStack(spacing: 12) {
                SummaryCard(title: "Glucose", value: glucose.isEmpty ? "—" : "\(glucose.count) readings", sub: glucose.isEmpty ? nil : "\(Int(glucose.compactMap(\.value).min() ?? 0))–\(Int(glucose.compactMap(\.value).max() ?? 0))")
                SummaryCard(title: "Meals", value: "\(meals.count)", sub: nil)
                SummaryCard(title: "Meds", value: "\(meds.count)", sub: nil)
            }

            Text("Totals (from logged meals)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

            HStack(spacing: 12) {
                SummaryCard(title: "Sugar", value: String(format: "%.0f g", totalSugar), sub: nil)
                SummaryCard(title: "Carbs", value: totalCarbs > 0 ? String(format: "%.0f g", totalCarbs) : "—", sub: nil)
                SummaryCard(title: "Calories", value: totalCal > 0 ? "\(totalCal) kcal" : "—", sub: nil)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear { load() }
        .onChange(of: date) { _, _ in load() }
    }

    private func sugarGuidanceSection(totalSugar: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How much sugar you can eat in a day")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            Text("Aim for about \(Int(recommendedDailySugarGrams)) g per day (often less for diabetes). Today: \(String(format: "%.0f", totalSugar)) g.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let fill = min(1, totalSugar / max(1, recommendedDailySugarGrams)) * w
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(white: 0.9))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(totalSugar <= recommendedDailySugarGrams ? Color(red: 0.2, green: 0.55, blue: 0.35) : Color.orange)
                            .frame(width: max(0, fill), height: 8)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                Text("\(String(format: "%.0f", totalSugar)) / \(Int(recommendedDailySugarGrams)) g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(red: 0.2, green: 0.55, blue: 0.35).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func load() {
        entries = (try? controller.entriesForDay(date)) ?? []
        //esto es nuevo
        let sugarOnly = entries.filter { $0.kind == HealthLogEntry.kindSugar }
           let meals = entries.filter { $0.kind == HealthLogEntry.kindMeal }
           let totalSugar = sugarOnly.compactMap(\.value).reduce(0, +)
                          + meals.compactMap(\.value).reduce(0, +)

           // 🔥 ENVÍA ALERTA AL WATCH (ahora de forma segura y asíncrona)
        SugarAlertManager.shared.evaluate(totalSugar: totalSugar, dailyLimit: 25)
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let sub: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            if let s = sub {
                Text(s)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(red: 0.2, green: 0.55, blue: 0.35).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ChartsView: View {
    let controller: HealthLogController
    let range: ChartRange

    @State private var glucose: [HealthLogEntry] = []
    @State private var sugar: [HealthLogEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !glucose.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blood glucose")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
                    Chart(glucose) { e in
                        if let v = e.value {
                            LineMark(
                                x: .value("Date", e.timestamp),
                                y: .value("mg/dL", v)
                            )
                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                            PointMark(
                                x: .value("Date", e.timestamp),
                                y: .value("mg/dL", v)
                            )
                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                        }
                    }
                    .chartYAxisLabel("mg/dL")
                    .frame(height: 180)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }

            if !sugar.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sugar intake")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
                    Chart(sugar) { e in
                        if let v = e.value, v > 0 {
                            BarMark(
                                x: .value("Date", e.timestamp),
                                y: .value("g", v)
                            )
                            .foregroundStyle(Color(red: 0.3, green: 0.6, blue: 0.4))
                        }
                    }
                    .chartYAxisLabel("g")
                    .frame(height: 160)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }

            if glucose.isEmpty && sugar.isEmpty {
                Text("Log glucose, meals, and sugar to see charts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
        }
        .onAppear { load() }
        .onChange(of: range) { _, _ in load() }
    }

    private func load() {
        let cal = Calendar.current
        let end = Date()
        let start: Date
        switch range {
        case .week: start = cal.date(byAdding: .day, value: -7, to: end) ?? end
        case .month: start = cal.date(byAdding: .day, value: -30, to: end) ?? end
        }
        let raw = (try? controller.glucoseEntries(from: start, to: end)) ?? []
        glucose = raw.filter { $0.value != nil }
        let all = (try? controller.entries(from: start, to: end)) ?? []
        sugar = all.filter { ($0.kind == HealthLogEntry.kindSugar || $0.kind == HealthLogEntry.kindMeal) && ($0.value ?? 0) > 0 }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}

/*import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDay = Date()
    @State private var range: ChartRange = .week

    private var controller: HealthLogController { HealthLogController(modelContext: modelContext) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Health dashboard")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

                dayPicker
                dailySummarySection
                chartsSection
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.98, blue: 0.96))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var dayPicker: some View {
        HStack {
            Text("Day")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            DatePicker("", selection: $selectedDay, displayedComponents: .date)
                .labelsHidden()
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var dailySummarySection: some View {
        DailySummaryView(controller: controller, date: selectedDay)
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Range", selection: $range) {
                Text("7 days").tag(ChartRange.week)
                Text("30 days").tag(ChartRange.month)
            }
            .pickerStyle(.segmented)

            ChartsView(controller: controller, range: range)
        }
    }
}

enum ChartRange {
    case week
    case month
}

/// WHO-style guideline: ~25 g added sugar per day for adults; often lower for people with diabetes.
private let recommendedDailySugarGrams: Double = 25

private struct DailySummaryView: View {
    let controller: HealthLogController
    let date: Date

    @State private var entries: [HealthLogEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily summary")
                .font(.headline)
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

            let glucose = entries.filter { $0.kind == HealthLogEntry.kindGlucose }
            let meals = entries.filter { $0.kind == HealthLogEntry.kindMeal }
            let sugarOnly = entries.filter { $0.kind == HealthLogEntry.kindSugar }
            let meds = entries.filter { $0.kind == HealthLogEntry.kindMedication }
            let totalSugar = sugarOnly.compactMap(\.value).reduce(0, +)
                           + meals.compactMap(\.value).reduce(0, +)
            let totalCarbs = meals.compactMap(\.secondaryValue).reduce(0, +)
            let totalCal = meals.compactMap(\.note)
                .compactMap { Int($0.replacingOccurrences(of: " kcal", with: "")) }
                .reduce(0, +)

            sugarGuidanceSection(totalSugar: totalSugar)

            HStack(spacing: 12) {
                SummaryCard(
                    title: "Glucose",
                    value: glucose.isEmpty ? "—" : "\(glucose.count) readings",
                    sub: glucose.isEmpty ? nil :
                        "\(Int(glucose.compactMap(\.value).min() ?? 0))–\(Int(glucose.compactMap(\.value).max() ?? 0))"
                )
                SummaryCard(title: "Meals", value: "\(meals.count)", sub: nil)
                SummaryCard(title: "Meds", value: "\(meds.count)", sub: nil)
            }

            Text("Totals (from logged meals)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

            HStack(spacing: 12) {
                SummaryCard(title: "Sugar", value: String(format: "%.0f g", totalSugar), sub: nil)
                SummaryCard(title: "Carbs", value: totalCarbs > 0 ? String(format: "%.0f g", totalCarbs) : "—", sub: nil)
                SummaryCard(title: "Calories", value: totalCal > 0 ? "\(totalCal) kcal" : "—", sub: nil)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear { load() }
        .onChange(of: date) { _, _ in load() }
    }

    private func sugarGuidanceSection(totalSugar: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How much sugar you can eat in a day")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            Text("Aim for about \(Int(recommendedDailySugarGrams)) g per day (often less for diabetes). Today: \(String(format: "%.0f", totalSugar)) g.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let fill = min(1, totalSugar / max(1, recommendedDailySugarGrams)) * w
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(white: 0.9))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(totalSugar <= recommendedDailySugarGrams
                                  ? Color(red: 0.2, green: 0.55, blue: 0.35)
                                  : Color.orange)
                            .frame(width: max(0, fill), height: 8)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                Text("\(String(format: "%.0f", totalSugar)) / \(Int(recommendedDailySugarGrams)) g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(red: 0.2, green: 0.55, blue: 0.35).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // ✅ AQUÍ VA LA MAGIA
    private func load() {
        entries = (try? controller.entriesForDay(date)) ?? []

        let sugarOnly = entries.filter { $0.kind == HealthLogEntry.kindSugar }
        let meals = entries.filter { $0.kind == HealthLogEntry.kindMeal }
        let totalSugar = sugarOnly.compactMap(\.value).reduce(0, +)
                       + meals.compactMap(\.value).reduce(0, +)

        // 🔥 ENVÍA ALERTA AL WATCH SI ESTÁS CERCA O TE PASASTE
        SugarAlertManager.shared.evaluate(totalSugar: totalSugar)
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let sub: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            if let s = sub {
                Text(s)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(red: 0.2, green: 0.55, blue: 0.35).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ChartsView: View {
    let controller: HealthLogController
    let range: ChartRange

    @State private var glucose: [HealthLogEntry] = []
    @State private var sugar: [HealthLogEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !glucose.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blood glucose")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
                    Chart(glucose) { e in
                        if let v = e.value {
                            LineMark(
                                x: .value("Date", e.timestamp),
                                y: .value("mg/dL", v)
                            )
                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                            PointMark(
                                x: .value("Date", e.timestamp),
                                y: .value("mg/dL", v)
                            )
                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                        }
                    }
                    .chartYAxisLabel("mg/dL")
                    .frame(height: 180)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }

            if !sugar.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sugar intake")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
                    Chart(sugar) { e in
                        if let v = e.value, v > 0 {
                            BarMark(
                                x: .value("Date", e.timestamp),
                                y: .value("g", v)
                            )
                            .foregroundStyle(Color(red: 0.3, green: 0.6, blue: 0.4))
                        }
                    }
                    .chartYAxisLabel("g")
                    .frame(height: 160)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }

            if glucose.isEmpty && sugar.isEmpty {
                Text("Log glucose, meals, and sugar to see charts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
        }
        .onAppear { load() }
        .onChange(of: range) { _, _ in load() }
    }

    private func load() {
        let cal = Calendar.current
        let end = Date()
        let start: Date
        switch range {
        case .week:
            start = cal.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = cal.date(byAdding: .day, value: -30, to: end) ?? end
        }
        let raw = (try? controller.glucoseEntries(from: start, to: end)) ?? []
        glucose = raw.filter { $0.value != nil }
        let all = (try? controller.entries(from: start, to: end)) ?? []
        sugar = all.filter {
            ($0.kind == HealthLogEntry.kindSugar || $0.kind == HealthLogEntry.kindMeal)
            && ($0.value ?? 0) > 0
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}

*/
