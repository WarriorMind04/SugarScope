//
//  SugarAlertView.swift
//  SugarScopeWatch Watch App
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//



import SwiftUI

struct SugarAlertView: View {
    let alert: SugarAlert
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: alert.level == "exceeded"
                  ? "exclamationmark.triangle.fill"
                  : "bolt.heart.fill")
                .font(.title)
                .foregroundStyle(alert.level == "exceeded" ? .red : .orange)

            Text(alert.level == "exceeded"
                 ? "Sugar Limit Exceeded"
                 : "Almost There")
                .font(.headline)

            Text("Today: \(Int(alert.sugar)) g")
                .font(.title3.bold())

            Text("Limit: \(Int(alert.limit)) g")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Got it") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
