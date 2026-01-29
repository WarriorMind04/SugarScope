//
//  WatchContentView.swift
//  SugarScope Watch
//
//  Simple reminder confirmations and quick log. Notifications appear on Watch;
//  use these buttons to confirm or quick-log from the wrist.
//

import SwiftUI
import WatchConnectivity

struct WatchContentView: View {
    @State private var glucoseValue = ""
    @State private var status = ""
    @State private var session: WCSession?

    var body: some View {
        List {
            Section("Quick log") {
                HStack {
                    TextField("Glucose", text: $glucoseValue)
                    Button("Log") { logGlucose() }
                }
            }
            Section("Confirm") {
                Button("Confirm medication") { sendConfirmMedication() }
                Button("Confirm glucose check") { sendConfirmGlucose() }
            }
            if !status.isEmpty {
                Section {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("SugarScope")
        .onAppear {
            if WCSession.isSupported() {
                let s = WCSession.default
                s.activate()
                session = s
            }
        }
    }

    private func logGlucose() {
        guard let v = Double(glucoseValue), v > 0 else {
            status = "Enter a value"
            return
        }
        send(["logGlucose": v])
        glucoseValue = ""
        status = "Logged \(Int(v)) mg/dL"
    }

    private func sendConfirmMedication() {
        send(["confirmMedication": true, "medicationName": "Medication"])
        status = "Confirmed"
    }

    private func sendConfirmGlucose() {
        send(["confirmGlucoseReminder": true])
        status = "Check confirmed"
    }

    private func send(_ dict: [String: Any]) {
        guard let s = session, s.isReachable else {
            status = "Phone not reachable"
            return
        }
        s.sendMessage(dict, replyHandler: { _ in }, errorHandler: { _ in status = "Send failed" })
    }
}
