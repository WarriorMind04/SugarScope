//
//  WatchConnectivityManager.swift
//  SugarScopeWatch Watch App
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

/*
import Foundation
import WatchConnectivity
import WatchKit
import Combine

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    var currentAlert: SugarAlert? {
        didSet {
            objectWillChange.send()
        }
    }
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("❌ Watch session activation error: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activated: \(activationState.rawValue)")
        }
    }
    
    // Para mensajes inmediatos (cuando la app está abierta)
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        print("📱➡️⌚️ Watch received immediate message: \(message)")
        handleMessage(message, immediate: true)
    }
    
    // Para mensajes en cola (cuando la app estaba cerrada) - AQUÍ ENVIAMOS LA NOTIFICACIÓN
    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("📱➡️⌚️ Watch received queued message: \(userInfo)")
        handleMessage(userInfo, immediate: false)
    }
    
    private func handleMessage(_ message: [String: Any], immediate: Bool) {
        // Manejar diferentes tipos de mensajes
        if message["type"] as? String == "sugarAlert" {
            handleSugarAlert(message, immediate: immediate)
        } else if let glucose = message["logGlucose"] as? Double {
            print("Glucose logged: \(glucose)")
        } else if message["confirmMedication"] != nil {
            print("Medication confirmed")
        } else if message["confirmGlucoseReminder"] != nil {
            print("Glucose reminder confirmed")
        }
    }
    
    private func handleSugarAlert(_ message: [String: Any], immediate: Bool) {
        guard let level = message["level"] as? String,
              let sugar = message["sugar"] as? Double,
              let limit = message["limit"] as? Double else {
            print("❌ Invalid sugar alert data")
            return
        }
        
        if immediate {
            // App está abierta - mostrar UI directamente + haptic
            let alert = SugarAlert(level: level, sugar: sugar, limit: limit)
            DispatchQueue.main.async {
                print("🔥 App is open - showing alert with haptic")
                WKInterfaceDevice.current().play(.notification)
                self.currentAlert = alert
            }
        } else {
            // App está cerrada - enviar notificación del sistema
            print("🔔 App is closed - sending system notification")
            NotificationManager.shared.sendSugarAlert(level: level, sugar: sugar, limit: limit)
        }
    }
}
*/
import Foundation
import WatchConnectivity
import WatchKit
import UserNotifications
import Combine

final class WatchConnectivityManager: NSObject, WCSessionDelegate, UNUserNotificationCenterDelegate {
    static let shared = WatchConnectivityManager()
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    var currentAlert: SugarAlert? {
        didSet { objectWillChange.send() }
    }
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Muestra la notificación aunque la app esté abierta
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Cuando el usuario toca la notificación → abre SugarAlertView
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if let level = info["level"] as? String,
           let sugar = info["sugar"] as? Double,
           let limit = info["limit"] as? Double {
            DispatchQueue.main.async {
                self.currentAlert = SugarAlert(level: level, sugar: sugar, limit: limit)
            }
        }
        completionHandler()
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("❌ Watch session activation error: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activated: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📱➡️⌚️ Watch received immediate message: \(message)")
        handleMessage(message, immediate: true)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        print("📱➡️⌚️ Watch received queued message: \(userInfo)")
        handleMessage(userInfo, immediate: false)
    }
    
    // MARK: - Private
    
    private func handleMessage(_ message: [String: Any], immediate: Bool) {
        if message["type"] as? String == "sugarAlert" {
            handleSugarAlert(message, immediate: immediate)
        }
    }
    
    private func handleSugarAlert(_ message: [String: Any], immediate: Bool) {
        guard let level = message["level"] as? String,
              let sugar = message["sugar"] as? Double,
              let limit = message["limit"] as? Double else {
            print("❌ Invalid sugar alert data")
            return
        }
        
        if immediate {
            let alert = SugarAlert(level: level, sugar: sugar, limit: limit)
            DispatchQueue.main.async {
                WKInterfaceDevice.current().play(level == "exceeded" ? .failure : .notification)
                self.currentAlert = alert
            }
        } else {
            NotificationManager.shared.sendSugarAlert(level: level, sugar: sugar, limit: limit)
        }
    }
}
