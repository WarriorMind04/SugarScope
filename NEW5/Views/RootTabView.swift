//
//  RootTabView.swift
//  NEW5
//
//  Main tab navigation: Log | Dashboard | Scan | Reports | AI Chat
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 2 // Scan is in the middle (tag 2)

    var body: some View {
        TabView(selection: $selectedTab) {

            // Tab 0 — Log
            NavigationStack {
                LogHealthView()
            }
            .background(Color.sugarOffWhite.ignoresSafeArea())
            .tabItem { Label("Log", systemImage: "list.clipboard") }
            .tag(0)

            // Tab 1 — Dashboard
            NavigationStack {
                DashboardView()
            }
            .background(Color.sugarOffWhite.ignoresSafeArea())
            .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            .tag(1)

            // Tab 2 — Scan (MIDDLE / default)
            NavigationStack {
                ScannerView()
            }
            .tabItem { Label("Scan", systemImage: "camera.viewfinder") }
            .tag(2)

            // Tab 3 — Reports
            NavigationStack {
                ReportsView()
            }
            .background(Color.sugarOffWhite.ignoresSafeArea())
            .tabItem { Label("Reports", systemImage: "doc.text.fill") }
            .tag(3)

            // Tab 4 — AI Chat
            NavigationStack {
                //                AIChatPlaceholderView()
                //                EmptyView()
                ZStack {
                    Color.sugarOffWhite
                        .ignoresSafeArea()
                    
                    Image("scanbackground")
                        .resizable()
                        .scaledToFill()
                    //                            .ignoresSafeArea()
                    
                    Color.sugarOffWhite.opacity(0.5)
                        .ignoresSafeArea()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.sugarOffWhite.ignoresSafeArea())
            .tabItem { Label("AI Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            .tag(4)
        }
        .tint(Color(hex: "2d6a4f"))
        .onAppear {
            WatchConnectivityManager.shared.setModelContext(modelContext)
            WatchConnectivityManager.shared.start()

            // Apply off-white background to tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.sugarOffWhite)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
