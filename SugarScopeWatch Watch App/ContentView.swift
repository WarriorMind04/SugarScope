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
    @State private var sugarAlert: SugarAlert?
    
    private let connectivityManager = WatchConnectivityManager.shared

    var body: some View {
        List {
            Section("Quick log") {
                HStack {
                    TextField("Glucose", text: $glucoseValue)
                    Button("Log") { logGlucose() }
                        .disabled(glucoseValue.isEmpty)
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
        .sheet(item: $sugarAlert) { alert in
            SugarAlertView(alert: alert)
        }
        .onReceive(connectivityManager.objectWillChange) { _ in
            if let alert = connectivityManager.currentAlert {
                sugarAlert = alert
                connectivityManager.currentAlert = nil // Limpiar después de mostrar
            }
        }
    }

    // MARK: - Actions

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
        guard WCSession.default.isReachable else {
            status = "Phone not reachable"
            return
        }
        WCSession.default.sendMessage(dict, replyHandler: nil) { error in
            DispatchQueue.main.async {
                status = "Send failed: \(error.localizedDescription)"
            }
        }
    }
}
