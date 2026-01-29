//
//  RootTabView.swift
//  NEW5
//
//  Main tab navigation: Scan | Log | Dashboard | Reminders | Reports.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScanFoodView()
            }
            .tabItem { Label("Scan", systemImage: "camera.viewfinder") }
            .tag(0)

            NavigationStack {
                LogHealthView()
            }
            .tabItem { Label("Log", systemImage: "list.clipboard") }
            .tag(1)

            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            .tag(2)

            NavigationStack {
                RemindersView()
            }
            .tabItem { Label("Reminders", systemImage: "bell.badge.fill") }
            .tag(3)

            NavigationStack {
                ReportsView()
            }
            .tabItem { Label("Reports", systemImage: "doc.text.fill") }
            .tag(4)
        }
        .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
        .onAppear {
            WatchConnectivityManager.shared.setModelContext(modelContext)
            WatchConnectivityManager.shared.start()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
