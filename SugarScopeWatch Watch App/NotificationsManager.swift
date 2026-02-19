//
//  NotificationsManager.swift
//  SugarScopeWatch Watch App
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//


import UserNotifications
import WatchKit

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Este es el método que faltaba
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification auth error: \(error.localizedDescription)")
            } else {
                print(granted ? "✅ Notifications granted" : "⚠️ Notifications denied")
            }
        }
    }

    func sendSugarAlert(level: String, sugar: Double, limit: Double) {
        let content = UNMutableNotificationContent()

        if level == "exceeded" {
            content.title = "⚠️ Sugar Limit Exceeded"
            content.body = "You've had \(Int(sugar))g of \(Int(limit))g today."
            content.sound = UNNotificationSound.defaultCritical
        } else {
            content.title = "🍬 Almost at Your Limit"
            content.body = "\(Int(sugar))g of \(Int(limit))g used today."
            content.sound = UNNotificationSound.default
        }

        content.userInfo = ["level": level, "sugar": sugar, "limit": limit]

        let request = UNNotificationRequest(
            identifier: "sugarAlert-\(level)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            }
        }

        // Haptic adicional
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(level == "exceeded" ? .failure : .notification)
        }
    }
}
