//
//  MealAnalysisViewProtTwoo.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 18/02/26.
//




import SwiftUI
import SwiftData
import UIKit

struct MealAnalysisViewProtTwoo: View {
    let items: [IdentifiedFoodItem]
    let image: UIImage?
    var onLogMeal: (([IdentifiedFoodItem]) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var didLog = false
    @State private var selectedItem: IdentifiedFoodItem?
    @State private var animateBar = false

    private let apiAnalyzer = FoodAnalyzer()

    private var totalSugar: Double    { items.reduce(0) { $0 + $1.nutrition.sugar } }
    private var totalCarbs: Double    { items.reduce(0) { $0 + $1.nutrition.carbohydrates } }
    private var totalFat: Double      { items.reduce(0) { $0 + $1.nutrition.fat } }
    private var totalCalories: Double { items.reduce(0) { $0 + $1.nutrition.calories } }
    private var totalProtein: Double  { items.reduce(0) { $0 + $1.nutrition.protein } }

    // Predicted peak glucose heuristic
    private var predictedPeakGlucose: Int {
        let base = 90.0
        let carbImpact = totalCarbs * 1.2
        let proteinDampen = totalProtein * 0.3
        let fatDampen = totalFat * 0.2
        return Int(min(280, base + carbImpact - proteinDampen - fatDampen))
    }

    private var glucoseStatus: (label: String, color: Color) {
        switch predictedPeakGlucose {
        case ..<100: return ("Low Impact", Color(hex: "3b82f6"))
        case 100..<140: return ("In Range", Color(hex: "22c55e"))
        case 140..<180: return ("Elevated", .orange)
        default: return ("High", .red)
        }
    }

    private var glucoseBarPosition: Double {
        let clamped = min(max(Double(predictedPeakGlucose), 70), 220)
        return (clamped - 70) / 150
    }

    private var smartInsight: String {
        if totalProtein > 20 && totalCarbs < 50 {
            return "Great balance! The high protein helps slow carb absorption. Consider a 10-minute walk after eating to perfectly smooth out your glucose spike."
        } else if totalCarbs > 60 {
            return "This meal is high in carbs. Pair it with a short walk or some protein to help blunt the glucose response."
        } else if totalFat > 20 {
            return "The fat content will slow digestion and may delay the glucose peak. Monitor your levels 2–3 hours after eating."
        }
        return "Balanced meal! The mix of macros should produce a moderate, steady glucose response. Stay hydrated."
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // Only the content below scrolls
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    imageSection
                    contentSection
                        .padding(.bottom, 88)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "eef2f7"))
                .scrollBounceBehavior(.basedOnSize)

                saveMealButton
            }
        }
        .background(Color(hex: "eef2f7").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            IngredientsView(foodItem: item, apiAnalyzer: apiAnalyzer)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) { animateBar = true }
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(hex: "d1dce8"))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: "3b82f6").opacity(0.3))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipped()

            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Retake")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
            }
            .padding(16)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(spacing: 12) {
            glucoseCard
            macroGrid
            insightCard
            detectedFoodsSection
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Glucose Card

    private var glucoseCard: some View {
        VStack(spacing: 16) {
            Text("Predicted Peak Glucose")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "64748b"))

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(predictedPeakGlucose)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0f172a"))
                Text("mg/dL")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "64748b"))
                    .padding(.bottom, 6)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                Text(glucoseStatus.label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(glucoseStatus.color)
            .clipShape(Capsule())

            VStack(spacing: 6) {
                ZStack(alignment: .leading) {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "f97316"), location: 0),
                            .init(color: Color(hex: "22c55e"), location: 0.2),
                            .init(color: Color(hex: "22c55e"), location: 0.72),
                            .init(color: Color(hex: "ef4444"), location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    GeometryReader { geo in
                        let xPos = geo.size.width * (animateBar ? min(max(glucoseBarPosition, 0), 1) : 0)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "0f172a"))
                            .frame(width: 3, height: 18)
                            .offset(x: max(0, xPos - 1.5), y: -5)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateBar)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 8)
                }
                .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
                .clipped()

                HStack {
                    Text("70")
                    Spacer()
                    Text("Target Range")
                    Spacer()
                    Text("180+")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "94a3b8"))
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Macro Grid

    private var macroGrid: some View {
        HStack(spacing: 0) {
            MacroCell(value: String(format: "%.0fg", totalCarbs),   label: "Carbs",   color: Color(hex: "3b82f6"))
            Divider().frame(height: 40)
            MacroCell(value: String(format: "%.0fg", totalProtein), label: "Protein", color: Color(hex: "0f172a"))
            Divider().frame(height: 40)
            MacroCell(value: "\(Int(totalCalories))",               label: "kcal",    color: Color(hex: "0f172a"))
        }
        .padding(.vertical, 18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SMART AI INSIGHTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "64748b"))
                .kerning(1.2)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "3b82f6"))
                    .padding(.top, 1)

                Text(smartInsight)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "1e293b"))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(16)
            .background(Color(hex: "fbbf24").opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Detected Foods

    private var detectedFoodsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DETECTED FOODS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "64748b"))
                .kerning(1.2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    DetectedFoodRow(item: item, onTap: { selectedItem = item })
                    if index < items.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Save Meal (sticky)

    private var saveMealButton: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.2)
            Button { logMeal() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                    Text(didLog ? "Saved!" : "Save Meal")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(didLog ? Color(hex: "22c55e") : Color(hex: "3b82f6"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .animation(.easeInOut(duration: 0.3), value: didLog)
            }
            .disabled(didLog)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "eef2f7"))
        }
    }

    

    // MARK: - Log

    private func logMeal() {
        let entry = HealthLogEntry(
            timestamp: Date(),
            kind: HealthLogEntry.kindMeal,
            value: totalSugar,
            unit: "g",
            secondaryValue: totalCarbs,
            note: "\(Int(totalCalories)) kcal",
            mealDescription: items.map(\.name).joined(separator: ", ")
        )
        modelContext.insert(entry)
        try? modelContext.save()
        didLog = true
        onLogMeal?(items)

        let controller = HealthLogController(modelContext: modelContext)
        let today = Date()
        let start = Calendar.current.startOfDay(for: today)
        let todayEntries = (try? controller.sugarEntries(from: start, to: today)) ?? []
        let todayTotal = todayEntries.compactMap(\.value).reduce(0, +)
        SugarAlertManager.shared.evaluate(totalSugar: todayTotal, dailyLimit: 25)
    }
}

// MARK: - MacroCell

private struct MacroCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "94a3b8"))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - DetectedFoodRow

private struct DetectedFoodRow: View {
    let item: IdentifiedFoodItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "0f172a"))
                    Text(item.nutrition.portionDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                Spacer()
                Text(String(format: "%.0fg", item.nutrition.carbohydrates))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0f172a"))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "cbd5e1"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MealAnalysisViewProtTwoo(
            items: [
                IdentifiedFoodItem(
                    name: "Grilled Salmon",
                    nutrition: NutritionInfo(calories: 280, carbohydrates: 0, sugar: 0, fat: 13, protein: 39, fiber: 0, portionDescription: "1 fillet (170g)"),
                    confidence: 0.93,
                    visionIdentifier: "salmon"
                ),
                IdentifiedFoodItem(
                    name: "Brown Rice",
                    nutrition: NutritionInfo(calories: 216, carbohydrates: 41, sugar: 0, fat: 1.8, protein: 5, fiber: 3.5, portionDescription: "1 cup, cooked"),
                    confidence: 0.89,
                    visionIdentifier: "rice"
                ),
                IdentifiedFoodItem(
                    name: "Steamed Broccoli",
                    nutrition: NutritionInfo(calories: 54, carbohydrates: 4, sugar: 1, fat: 0.6, protein: 3.7, fiber: 2.4, portionDescription: "1 cup, chopped"),
                    confidence: 0.91,
                    visionIdentifier: "broccoli"
                ),
            ],
            image: nil,
            onLogMeal: nil
        )
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
