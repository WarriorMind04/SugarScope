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
    @State private var animateRings = false

    private let apiAnalyzer = FoodAnalyzer()

    private var totalSugar: Double    { items.reduce(0) { $0 + $1.nutrition.sugar } }
    private var totalCarbs: Double    { items.reduce(0) { $0 + $1.nutrition.carbohydrates } }
    private var totalFat: Double      { items.reduce(0) { $0 + $1.nutrition.fat } }
    private var totalCalories: Double { items.reduce(0) { $0 + $1.nutrition.calories } }
    private var totalProtein: Double  { items.reduce(0) { $0 + $1.nutrition.protein } }

    // Health score heurístico (0–10) basado en ratio azúcar/calorías
    private var healthScore: Double {
        guard totalCalories > 0 else { return 5 }
        let sugarRatio = (totalSugar * 4) / totalCalories
        return max(0, min(10, 10 - sugarRatio * 20))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(red: 0.97, green: 0.96, blue: 0.93))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            IngredientsView(foodItem: item, apiAnalyzer: apiAnalyzer)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.9).delay(0.2)) { animateRings = true } }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.18, green: 0.22, blue: 0.18),
                                         Color(red: 0.28, green: 0.38, blue: 0.28)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 64))
                                .foregroundStyle(.white.opacity(0.15))
                        )
                }
            }
            .frame(height: 300)
            .clipped()

            // Gradiente inferior para legibilidad
            LinearGradient(
                colors: [.clear, Color(red: 0.97, green: 0.96, blue: 0.93)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)

            // Título de la comida
            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Result")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(1.5)
                Text(items.first?.name ?? "Your Meal")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.1))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            caloriesRow
            macroRingsRow
            healthScoreRow
            foodListSection
            logButton
            disclaimer
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 40)
    }

    // Fila de calorías totales
    private var caloriesRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("\(Int(totalCalories)) Kcal")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.1))
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                )
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // Tres anillos animados: Carbs, Protein, Fats
    private var macroRingsRow: some View {
        HStack(spacing: 0) {
            MacroRing(label: "Carbs",   value: totalCarbs,   max: 60, unit: "g",
                      color: Color(red: 0.95, green: 0.65, blue: 0.2),  animate: animateRings)
            MacroRing(label: "Protein", value: totalProtein, max: 50, unit: "g",
                      color: Color(red: 0.35, green: 0.6, blue: 0.85),  animate: animateRings)
            MacroRing(label: "Fats",    value: totalFat,     max: 40, unit: "g",
                      color: Color(red: 0.35, green: 0.72, blue: 0.5),  animate: animateRings)
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // Barra de health score
    private var healthScoreRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text(healthScoreLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.1))
                Spacer()
                Text(String(format: "%.0f/10", healthScore))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.9))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(healthScoreColor)
                        .frame(width: animateRings ? geo.size.width * (healthScore / 10) : 0, height: 6)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: animateRings)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var healthScoreLabel: String {
        switch healthScore {
        case 8...: return "High Health Score"
        case 5..<8: return "Moderate Health Score"
        default:    return "Low Health Score"
        }
    }

    private var healthScoreColor: Color {
        switch healthScore {
        case 7...: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case 4..<7: return .orange
        default:   return .red
        }
    }

    // Lista de alimentos identificados
    private var foodListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Identified Foods")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.8)

            ForEach(items) { item in
                FoodRowView(item: item, onShowIngredients: { selectedItem = item })
            }
        }
    }

    // Botón log
    private var logButton: some View {
        Button {
            logMeal()
        } label: {
            HStack(spacing: 8) {
                if didLog {
                    Image(systemName: "checkmark")
                    Text("Logged!")
                } else {
                    Text("Log this meal")
                }
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                didLog
                ? Color(red: 0.2, green: 0.55, blue: 0.35).opacity(0.5)
                : Color(red: 0.08, green: 0.08, blue: 0.08)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(didLog)
        .animation(.easeInOut(duration: 0.3), value: didLog)
    }

    private var disclaimer: some View {
        Text("Nutrition and portions are estimates. Focus on sugar and carbs for diabetes management. Consult a dietitian for personalized advice.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
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
    }
}

// MARK: - MacroRing

private struct MacroRing: View {
    let label: String
    let value: Double
    let max: Double
    let unit: String
    let color: Color
    let animate: Bool

    private var progress: Double { Swift.min(1, value / max) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                    .animation(.easeOut(duration: 0.9).delay(0.2), value: animate)
                VStack(spacing: 1) {
                    Text("\(Int(value))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.1))
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - FoodRowView

private struct FoodRowView: View {
    let item: IdentifiedFoodItem
    let onShowIngredients: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.1))
                Spacer()
                Text(item.nutrition.caloriesFormatted)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text(item.nutrition.portionDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    NutriBadge(label: "Sugar",   value: item.nutrition.sugar,          color: .red)
                    NutriBadge(label: "Carbs",   value: item.nutrition.carbohydrates,  color: Color(red: 0.95, green: 0.65, blue: 0.2))
                    NutriBadge(label: "Fat",     value: item.nutrition.fat,            color: Color(red: 0.35, green: 0.72, blue: 0.5))
                    NutriBadge(label: "Protein", value: item.nutrition.protein,        color: Color(red: 0.35, green: 0.6, blue: 0.85))
                }
            }

            Button(action: onShowIngredients) {
                Label("View ingredients", systemImage: "list.bullet")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

private struct NutriBadge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        Text("\(label): \(String(format: "%.1f", value))g")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

#Preview {
    NavigationStack {
        MealAnalysisViewProtTwoo(
            items: [
                IdentifiedFoodItem(
                    name: "Spaghetti al pomodoro",
                    nutrition: NutritionInfo(calories: 420, carbohydrates: 62, sugar: 8, fat: 11, protein: 14, fiber: 4, portionDescription: "1 portion (280 g)"),
                    confidence: 0.91,
                    visionIdentifier: "pasta"
                ),
                IdentifiedFoodItem(
                    name: "Basil garnish",
                    nutrition: NutritionInfo(calories: 5, carbohydrates: 0.6, sugar: 0.1, fat: 0.1, protein: 0.4, fiber: 0.3, portionDescription: "few leaves (5 g)"),
                    confidence: 0.85,
                    visionIdentifier: "basil"
                ),
            ],
            image: nil,
            onLogMeal: nil
        )
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
