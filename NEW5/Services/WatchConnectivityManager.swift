//
//  WatchConnectivityManager.swift
//  NEW5
//
//  Receives messages from Apple Watch (reminder confirmations, quick log).
//  Ensure Watch app target uses WatchConnectivity and shares the app group if needed.
//
import Combine
import Foundation
import WatchConnectivity
import SwiftData

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    var modelContext: ModelContext?

    private override init() {
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            handleWatchMessage(message)
            replyHandler(["ok": true])
        }
    }

    private func handleWatchMessage(_ message: [String: Any]) {
        guard let ctx = modelContext else { return }
        let controller = HealthLogController(modelContext: ctx)

        if let raw = message["logGlucose"] as? Double {
            let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindGlucose, value: raw, unit: "mg/dL", note: "Logged from Watch")
            controller.addEntry(e)
        }
        if message["confirmMedication"] != nil {
            let name = (message["medicationName"] as? String) ?? "Medication"
            let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindMedication, note: "\(name) (confirmed on Watch)")
            controller.addEntry(e)
        }
        if message["confirmGlucoseReminder"] != nil {
            let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindGlucose, value: nil, unit: nil, note: "Check confirmed on Watch")
            controller.addEntry(e)
        }
    }
}
