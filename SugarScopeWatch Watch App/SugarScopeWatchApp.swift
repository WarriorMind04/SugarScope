//
//  SugarScopeWatchApp.swift
//  SugarScope Watch
//
//  Watch app for reminder confirmations and quick log. Add this target in Xcode:
//  File → New → Target → Watch App, then add these files to the Watch target.
//

/*import SwiftUI

@main
struct SugarScopeWatchApp: App {
    init() {
            _ = WatchConnectivityManager.shared
            // Solicitar permisos de notificación al iniciar
            NotificationManager.shared.requestAuthorization()
        }
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
*/
import SwiftUI
import UserNotifications

@main
struct SugarScopeWatchApp: App {
    init() {
        _ = WatchConnectivityManager.shared
        
        // Registrar delegate ANTES de pedir permisos
        UNUserNotificationCenter.current().delegate = WatchConnectivityManager.shared
        
        // Solicitar permisos de notificación al iniciar
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
