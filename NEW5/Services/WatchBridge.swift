//
//  WatchBridge.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

/*import Foundation
import WatchConnectivity

final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func sendAlert(level: SugarAlertLevel, sugar: Double, limit: Double) {
        print("📱 Attempting to send alert: \(level.rawValue), sugar: \(sugar), limit: \(limit)")
        
        let message: [String: Any] = [
            "type": "sugarAlert",
            "level": level.rawValue,
            "sugar": sugar,
            "limit": limit,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Intenta primero con sendMessage si está reachable (inmediato con haptic)
        if WCSession.default.isReachable {
            print("📱➡️⌚️ Watch reachable - sending immediate message")
            WCSession.default.sendMessage(message, replyHandler: { reply in
                print("✅ Watch replied: \(reply)")
            }) { error in
                print("❌ Send failed: \(error.localizedDescription)")
            }
        } else {
            // Si no está reachable, usa transferUserInfo (se entrega cuando abra la app)
            print("📱➡️⌚️ Watch NOT reachable - using transferUserInfo")
            WCSession.default.transferUserInfo(message)
        }
    }

    // MARK: - Required WCSessionDelegate methods

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("❌ iOS session activation error: \(error.localizedDescription)")
        } else {
            print("✅ iOS session activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {}
}

*/

import Foundation
import WatchConnectivity

final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()
    
    private var isSessionReady = false
    private let sessionQueue = DispatchQueue(label: "com.sugarscope.watchbridge")

    private override init() {
        super.init()
        // No activar aquí, hacerlo de forma lazy
    }
    
    private func ensureSessionActivated() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard WCSession.isSupported() else {
                print("⚠️ WatchConnectivity not supported")
                return
            }
            
            let session = WCSession.default
            
            // Solo configurar si aún no se ha hecho
            if session.delegate == nil {
                session.delegate = self
            }
            
            // Solo activar si no está activado
            if session.activationState == .notActivated {
                session.activate()
            } else if session.activationState == .activated {
                self.isSessionReady = true
            }
        }
    }

    func sendAlert(level: SugarAlertLevel, sugar: Double, limit: Double) {
        // Asegurar que la sesión esté activada
        ensureSessionActivated()
        
        sessionQueue.async {
            guard self.isSessionReady else {
                print("⚠️ WCSession not ready yet, skipping alert")
                return
            }
            
            let message: [String: Any] = [
                "type": "sugarAlert",
                "level": level.rawValue,
                "sugar": sugar,
                "limit": limit,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            DispatchQueue.main.async {
                if WCSession.default.isReachable {
                    print("📱➡️⌚️ Sending immediate message")
                    WCSession.default.sendMessage(message, replyHandler: nil) { error in
                        print("❌ Send failed: \(error.localizedDescription)")
                    }
                } else {
                    print("📱➡️⌚️ Watch not reachable, using transferUserInfo")
                    WCSession.default.transferUserInfo(message)
                }
            }
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        sessionQueue.async {
            self.isSessionReady = (activationState == .activated)
            if let error = error {
                print("❌ Session activation error: \(error.localizedDescription)")
            } else {
                print("✅ Session activated: \(activationState.rawValue)")
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        sessionQueue.async {
            self.isSessionReady = false
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        sessionQueue.async {
            self.isSessionReady = false
            session.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 Received message: \(message)")
    }
}

enum SugarAlertLevel: String {
    case warning
    case exceeded
}
