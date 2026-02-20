import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 2 // Default to Scan
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            SugarGradientBackground()
            
            // Main Content Area
            VStack(spacing: 0) {
                switch selectedTab {
                case 0:
                    PlaceholderView(title: "Dashboard", icon: "house.fill")
                case 1:
                    PlaceholderView(title: "Log", icon: "list.bullet.clipboard.fill")
                case 2:
                    // ScannerView owns its own NavigationStack + analysis flow
                    ScannerView()
                case 3:
                    PlaceholderView(title: "Reports", icon: "chart.bar.doc.horizontal.fill")
                case 4:
                    PlaceholderView(title: "AI Chat", icon: "bubble.left.and.bubble.right.fill")
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)
            
            // Custom Tab Bar
            CustomTabBar(selection: $selectedTab, onScanTap: {
                selectedTab = 2
            })
        }
        .ignoresSafeArea(.keyboard)
    }
}

// Helper for other tabs
struct PlaceholderView: View {
    let title: String
    let icon: String
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Color.sugarSecondary)
                .symbolEffect(.bounce, value: animate)
            
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Color.sugarDarkText)
            
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Background is handled by parent ZStack
        .onAppear { animate.toggle() }
    }
}

#Preview {
    ContentView()
}
