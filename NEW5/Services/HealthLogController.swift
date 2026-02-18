//
//  HealthLogController.swift
//  NEW5
//
//  Fetches and saves health log entries, medications, reminder configs.
//

/*import Foundation
 import SwiftData
 
 @MainActor
 final class HealthLogController {
 
 private let modelContext: ModelContext
 
 init(modelContext: ModelContext) {
 self.modelContext = modelContext
 }
 
 // MARK: - Health log entries
 
 func addEntry(_ entry: HealthLogEntry) {
 modelContext.insert(entry)
 try? modelContext.save()
 }
 
 func entries(from start: Date, to end: Date) throws -> [HealthLogEntry] {
 let descriptor = FetchDescriptor<HealthLogEntry>(
 predicate: #Predicate { $0.timestamp >= start && $0.timestamp <= end },
 sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
 )
 return try modelContext.fetch(descriptor)
 }
 
 func entriesForDay(_ date: Date) throws -> [HealthLogEntry] {
 let cal = Calendar.current
 let start = cal.startOfDay(for: date)
 guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
 return try entries(from: start, to: end)
 }
 
 func glucoseEntries(from start: Date, to end: Date) throws -> [HealthLogEntry] {
 let all = try entries(from: start, to: end)
 return all.filter { $0.kind == HealthLogEntry.kindGlucose }
 }
 
 func sugarEntries(from start: Date, to end: Date) throws -> [HealthLogEntry] {
 let all = try entries(from: start, to: end)
 return all.filter { $0.kind == HealthLogEntry.kindSugar || $0.kind == HealthLogEntry.kindMeal }
 }
 
 func deleteEntry(_ entry: HealthLogEntry) {
 modelContext.delete(entry)
 try? modelContext.save()
 }
 
 // MARK: - Medications
 
 func addMedication(_ m: Medication) {
 modelContext.insert(m)
 try? modelContext.save()
 }
 
 func medications() throws -> [Medication] {
 let d = FetchDescriptor<Medication>(sortBy: [SortDescriptor(\.name)])
 return try modelContext.fetch(d)
 }
 
 func deleteMedication(_ m: Medication) {
 modelContext.delete(m)
 try? modelContext.save()
 }
 
 // MARK: - Reminder configs
 
 func addReminderConfig(_ r: ReminderConfig) {
 modelContext.insert(r)
 try? modelContext.save()
 }
 
 func reminderConfigs() throws -> [ReminderConfig] {
 let d = FetchDescriptor<ReminderConfig>()
 return try modelContext.fetch(d)
 }
 
 func deleteReminderConfig(_ r: ReminderConfig) {
 modelContext.delete(r)
 try? modelContext.save()
 }
 }
 */

import Foundation
import SwiftData

@MainActor
final class HealthLogController {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Health log entries

    func addEntry(_ entry: HealthLogEntry, dailyLimit: Double? = nil) {
        modelContext.insert(entry)
        try? modelContext.save()

        // Evaluar límite solo si es azúcar o comida
        guard entry.kind == HealthLogEntry.kindSugar || entry.kind == HealthLogEntry.kindMeal,
              let limit = dailyLimit, limit > 0 else { return }

        // Calcular total del día incluyendo el entry recién guardado
        let today = Date()
        let start = Calendar.current.startOfDay(for: today)
        let todayEntries = (try? sugarEntries(from: start, to: today)) ?? []
        let todayTotal = todayEntries.compactMap(\.value).reduce(0, +)

        SugarAlertManager.shared.evaluate(totalSugar: todayTotal, dailyLimit: limit)
    }

    func entries(from start: Date, to end: Date) throws -> [HealthLogEntry] {
        let descriptor = FetchDescriptor<HealthLogEntry>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp <= end },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func entriesForDay(_ date: Date) throws -> [HealthLogEntry] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        return try entries(from: start, to: end)
    }

    func glucoseEntries(from start: Date, to end: Date) throws -> [HealthLogEntry] {
        let all = try entries(from: start, to: end)
        return all.filter { $0.kind == HealthLogEntry.kindGlucose }
    }

    func sugarEntries(from start: Date, to end: Date) throws -> [HealthLogEntry] {
        let all = try entries(from: start, to: end)
        return all.filter { $0.kind == HealthLogEntry.kindSugar || $0.kind == HealthLogEntry.kindMeal }
    }

    func deleteEntry(_ entry: HealthLogEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: - Medications

    func addMedication(_ m: Medication) {
        modelContext.insert(m)
        try? modelContext.save()
    }

    func medications() throws -> [Medication] {
        let d = FetchDescriptor<Medication>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(d)
    }

    func deleteMedication(_ m: Medication) {
        modelContext.delete(m)
        try? modelContext.save()
    }

    // MARK: - Reminder configs

    func addReminderConfig(_ r: ReminderConfig) {
        modelContext.insert(r)
        try? modelContext.save()
    }

    func reminderConfigs() throws -> [ReminderConfig] {
        let d = FetchDescriptor<ReminderConfig>()
        return try modelContext.fetch(d)
    }

    func deleteReminderConfig(_ r: ReminderConfig) {
        modelContext.delete(r)
        try? modelContext.save()
    }
}
