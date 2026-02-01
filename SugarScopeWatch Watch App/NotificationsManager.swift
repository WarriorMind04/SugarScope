//
//  NotificationsManager.swift
//  SugarScopeWatch Watch App
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

import Foundation
import UserNotifications
import WatchKit

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    func sendSugarAlert(level: String, sugar: Double, limit: Double) {
        let content = UNMutableNotificationContent()
        
        // Configurar el contenido según el nivel
        if level == "exceeded" {
            content.title = "⚠️ Sugar Limit Exceeded"
            content.body = "You've consumed \(Int(sugar))g of sugar today. Your limit is \(Int(limit))g."
            content.sound = .defaultCritical
        } else {
            content.title = "⚡️ Sugar Warning"
            content.body = "You're at \(Int(sugar))g of sugar today. Getting close to your \(Int(limit))g limit."
            content.sound = .default
        }
        
        content.categoryIdentifier = "SUGAR_ALERT"
        content.userInfo = [
            "level": level,
            "sugar": sugar,
            "limit": limit
        ]
        
        // Crear el trigger (inmediato)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Crear la request con ID único
        let request = UNNotificationRequest(
            identifier: "sugar-alert-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Programar la notificación
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled successfully")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
