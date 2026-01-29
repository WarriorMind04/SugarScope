//
//  NEW5App.swift
//  NEW5
//
//  SugarScope — diabetes-focused meal scan, health tracking, reminders, reports.
//

import SwiftUI
import SwiftData

@main
struct NEW5App: App {

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self])
    }
}
