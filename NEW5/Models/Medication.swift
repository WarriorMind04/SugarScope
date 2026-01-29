//
//  Medication.swift
//  NEW5
//
//  SwiftData model for medications and reminder times.
//

import Foundation
import SwiftData

@Model
final class Medication: Identifiable {
    var id: UUID
    var name: String
    var dose: String?
    var reminderTimes: [String] // "HH:mm" e.g. "08:00", "20:00"
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        dose: String? = nil,
        reminderTimes: [String] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.dose = dose
        self.reminderTimes = reminderTimes
        self.isActive = isActive
    }
}
