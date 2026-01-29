//
//  ReminderConfig.swift
//  NEW5
//
//  SwiftData model for smart reminders: glucose checks, meal times.
//

import Foundation
import SwiftData

@Model
final class ReminderConfig: Identifiable {
    var id: UUID
    var type: String // "glucose" | "meal"
    var times: [String] // "HH:mm"
    var isEnabled: Bool
    var label: String?

    init(
        id: UUID = UUID(),
        type: String,
        times: [String] = [],
        isEnabled: Bool = true,
        label: String? = nil
    ) {
        self.id = id
        self.type = type
        self.times = times
        self.isEnabled = isEnabled
        self.label = label
    }

    static let typeGlucose = "glucose"
    static let typeMeal = "meal"
}
