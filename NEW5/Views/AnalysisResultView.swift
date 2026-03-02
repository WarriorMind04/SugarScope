
import SwiftUI

struct AnalysisResultView: View {
    var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header (Back Arrow & Cancel)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.sugarDarkGray)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.sugarDarkGray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // Top Image Section
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.08), radius: 15, y: 10)
                } else {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 280)
                        .overlay(Text("No Image").foregroundColor(.gray))
                        .padding(.horizontal, 24)
                }
                
                // Content Section
                VStack(spacing: 24) {
                    
                    // Title Header
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Vanilla Ice Cream")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.sugarDarkText)
                        
                        Text("1 serving • 230g")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    // AI Nutrition Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutritional Analysis")
                            .font(.headline)
                            .foregroundColor(.sugarDarkText)
                        
                        HStack(spacing: 12) {
                            MacroView(value: "186", unit: "Kcal", label: "Calories", color: .orange, progress: 0.75)
                            MacroView(value: "34g", unit: "Carbs", label: "Carbs", color: .sugarSkyBlue, progress: 0.6)
                            MacroView(value: "10g", unit: "Protein", label: "Protein", color: .sugarPurple, progress: 0.4)
                            MacroView(value: "3g", unit: "Fat", label: "Fats", color: .green, progress: 0.3)
                        }
                    }
                    .padding(20)
                    .glassCardStyle()
                    
                    // Blood Sugar Impact
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.red)
                            Text("Blood Sugar Impact")
                                .font(.headline)
                                .foregroundColor(.sugarDarkText)
                            Spacer()
                            Text("Moderate")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        Text("Glycemic Load: 15")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Combines moderate carbs with some fat. Likely a steady rise.")
                            .font(.caption)
                            .foregroundColor(.sugarDarkText)
                    }
                    .padding(20)
                    .glassCardStyle()
                    
                    // Health Score
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Health Score")
                                .font(.headline)
                                .foregroundColor(.sugarDarkText)
                            Spacer()
                            Text("7/10")
                                .font(.title3.bold())
                                .foregroundColor(.sugarSecondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.sugarSecondary)
                                    .frame(width: geo.size.width * 0.7, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(20)
                    .glassCardStyle()

                    // ⚠️ DEBUG — borra esta sección antes de publicar
                    debugSection

                    Spacer(minLength: 20)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button("Add to Log") { }
                            .secondaryButtonStyle()
                            .glassCardStyle()
                        
                        Button("Ask AI") { }
                            .primaryButtonStyle(color: .sugarDarkText)
                    }
                    .padding(.bottom, 30)
                }
                .padding(24)
            }
        }
        .ignoresSafeArea()
        .background(SugarGradientBackground())
        .navigationBarHidden(true)
    }

    // ⚠️ DEBUG — borra todo este bloque antes de publicar en App Store
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Watch Alert Debug", systemImage: "ant.fill")
                .font(.headline)
                .foregroundColor(.gray)

            Button {
                UserDefaults.standard.removeObject(forKey: "sugarAlert_log")
                SugarAlertManager.shared.evaluate(totalSugar: 30, dailyLimit: 25)
                print("🚨 Alerta exceeded forzada")
            } label: {
                Label("Force: Limit Exceeded", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                UserDefaults.standard.removeObject(forKey: "sugarAlert_log")
                SugarAlertManager.shared.evaluate(totalSugar: 22, dailyLimit: 25)
                print("⚠️ Alerta warning forzada")
            } label: {
                Label("Force: Almost at Limit", systemImage: "bolt.heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                UserDefaults.standard.removeObject(forKey: "sugarAlert_log")
                print("🧹 Cache de alertas limpiado")
            } label: {
                Label("Reset Alert Cache", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .glassCardStyle()
    }
}

// MARK: - MacroView

struct MacroView: View {
    let value: String
    let unit: String
    let label: String
    let color: Color
    var progress: Double = 0.7
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: progress)
                
                VStack(spacing: -2) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.sugarDarkText)
                    Text(unit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 60, height: 60)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AnalysisResultView(image: UIImage(systemName: "photo"))
}
