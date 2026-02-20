import SwiftUI

struct CustomTabBar: View {
    @Binding var selection: Int
    var onScanTap: () -> Void
    
    // Icons for the tab bar
    let items: [(icon: String, name: String)] = [
        ("house", "Dashboard"),
        ("list.bullet.clipboard", "Log"),
        ("camera.viewfinder", ""), // Center scan button
        ("chart.bar.doc.horizontal", "Reports"),
        ("bubble.left.and.bubble.right", "AI Chat")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                if index == 2 {
                    // Center Scan Button (Floating)
                    Button(action: onScanTap) {
                        ZStack {
                            Circle()
                                .fill(Color.sugarSecondary) // Updated to Mint/Green as requested
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.sugarSecondary.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "plus") // Simple Plus or Scan icon
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -20)
                } else {
                    // Standard Tab Item
                    Button {
                        selection = index
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: index == selection ? items[index].icon + ".fill" : items[index].icon)
                                .font(.system(size: 20))
                            
                            // Optional: Hide text for cleaner look, or keep small
                            if selection == index {
                                Circle()
                                    .fill(Color.sugarSecondary)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .foregroundColor(selection == index ? .sugarDarkText : .gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24) // Extra padding for floating look
        .background(
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24) // Floating margin
        .padding(.bottom, 10)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.sugarPrimary.ignoresSafeArea()
        CustomTabBar(selection: .constant(0), onScanTap: {})
    }
}
