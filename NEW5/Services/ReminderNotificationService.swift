//
//  ReminderNotificationService.swift
//  NEW5
//
//  Schedules local notifications for medication, glucose checks, meal times.
//  Notifications appear on iPhone and Apple Watch when the watch app is installed.
//

import Foundation
import UserNotifications

struct ReminderNotificationService {

    static let shared = ReminderNotificationService()

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            return try await center.requestAuthorization(options: options)
        } catch {
            return false
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Schedule notifications for medications, glucose reminders, meal reminders.
    func schedule(
        medications: [Medication],
        glucoseConfigs: [ReminderConfig],
        mealConfigs: [ReminderConfig]
    ) {
        cancelAll()
        for m in medications where m.isActive {
            for t in m.reminderTimes {
                schedule(title: "Medication", body: "\(m.name)\(m.dose.map { " \($0)" } ?? "")", time: t, id: "med-\(m.id.uuidString)-\(t)")
            }
        }
        for r in glucoseConfigs where r.isEnabled {
            for t in r.times {
                schedule(title: "Blood glucose check", body: r.label ?? "Time to check your blood sugar.", time: t, id: "glucose-\(r.id.uuidString)-\(t)")
            }
        }
        for r in mealConfigs where r.isEnabled {
            for t in r.times {
                schedule(title: "Meal reminder", body: r.label ?? "Time for your meal.", time: t, id: "meal-\(r.id.uuidString)-\(t)")
            }
        }
    }

    private func schedule(title: String, body: String, time: String, id: String) {
        let comps = parseTime(time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "SUGARSCOPE_REMINDER"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { _ in })
    }

    private func parseTime(_ time: String) -> DateComponents {
        let parts = time.split(separator: ":")
        var comps = DateComponents()
        comps.hour = Int(parts.first ?? "0")
        comps.minute = parts.count > 1 ? Int(parts[1]) : 0
        return comps
    }
}
