//
//  HealthLogEntry.swift
//  NEW5
//
//  SwiftData model for daily health logs: glucose, meals, sugar, medications.
//

import Foundation
import SwiftData

@Model
final class HealthLogEntry: Identifiable {
    var id: UUID
    var timestamp: Date
    var kind: String // "glucose" | "meal" | "sugar" | "medication"
    var value: Double?
    var unit: String?
    var secondaryValue: Double?
    var note: String?
    var mealDescription: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        kind: String,
        value: Double? = nil,
        unit: String? = nil,
        secondaryValue: Double? = nil,
        note: String? = nil,
        mealDescription: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.value = value
        self.unit = unit
        self.secondaryValue = secondaryValue
        self.note = note
        self.mealDescription = mealDescription
    }

    static let kindGlucose = "glucose"
    static let kindMeal = "meal"
    static let kindSugar = "sugar"
    static let kindMedication = "medication"
}
