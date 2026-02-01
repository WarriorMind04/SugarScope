//
//  WatchSessionHandler.swift
//  SugarScopeWatch Watch App
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

/*import WatchConnectivity
import WatchKit

final class WatchSessionHandler: NSObject, WCSessionDelegate {
    static let shared = WatchSessionHandler()

    var onAlert: ((SugarAlert) -> Void)?

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {

        guard message["type"] as? String == "sugarAlert",
              let level = message["level"] as? String,
              let sugar = message["sugar"] as? Double,
              let limit = message["limit"] as? Double else { return }

        let alert = SugarAlert(level: level, sugar: sugar, limit: limit)

        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(.notification) // 🔥 HAPTIC
            self.onAlert?(alert)
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}
*/
