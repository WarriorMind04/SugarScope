//
//  MealAnalysisView.swift
//  NEW5
//
//  Presents analyzed meal: food names, portions, sugar, carbs, fat, calories.
//  Designed for people with diabetes.
//

import SwiftUI
import SwiftData
import UIKit

struct MealAnalysisView: View {
    let items: [IdentifiedFoodItem]
    let image: UIImage?
    var onLogMeal: (([IdentifiedFoodItem]) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var didLog = false

    private var totalSugar: Double { items.reduce(0) { $0 + $1.nutrition.sugar } }
    private var totalCarbs: Double { items.reduce(0) { $0 + $1.nutrition.carbohydrates } }
    private var totalFat: Double { items.reduce(0) { $0 + $1.nutrition.fat } }
    private var totalCalories: Double { items.reduce(0) { $0 + $1.nutrition.calories } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(white: 0.9), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                VStack(alignment: .leading, spacing: 20) {
                    foodListSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.96, green: 0.98, blue: 0.96))
        .navigationTitle("Meal analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func logMeal() {
        let sugar = totalSugar
        let carbs = totalCarbs
        let cal = totalCalories
        let names = items.map(\.name).joined(separator: ", ")
        let entry = HealthLogEntry(
            timestamp: Date(),
            kind: HealthLogEntry.kindMeal,
            value: sugar,
            unit: "g",
            secondaryValue: carbs,
            note: "\(Int(cal)) kcal",
            mealDescription: names.isEmpty ? nil : names
        )
        modelContext.insert(entry)
        try? modelContext.save()
        didLog = true
        onLogMeal?(items)
    }

    private var foodListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identified foods")
                .font(.headline)
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

            ForEach(items) { item in
                FoodRowView(item: item)
            }

            Button {
                logMeal()
            } label: {
                    Label("Log this meal", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.2, green: 0.55, blue: 0.35))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(didLog)
                .opacity(didLog ? 0.6 : 1)
                .padding(.top, 8)

            Text("Nutrition and portions are estimates. Focus on sugar and carbs for diabetes management. Consult a dietitian for personalized advice.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }
}

private struct FoodRowView: View {
    let item: IdentifiedFoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .foregroundStyle(Color.black)
                Spacer()
                Text(item.nutrition.caloriesFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .foregroundStyle(Color.black)
            }

            Text(item.nutrition.portionDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .foregroundStyle(Color.black)

            HStack(spacing: 16) {
                Label(item.nutrition.sugarPerServingFormatted, systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.35))
                Label(item.nutrition.carbsPerServingFormatted, systemImage: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.3, green: 0.55, blue: 0.4))
                Label(item.nutrition.fatPerServingFormatted, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.96, green: 0.98, blue: 0.96)) //white
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        MealAnalysisView(
            items: [
                IdentifiedFoodItem(
                    name: "Apple",
                    nutrition: NutritionInfo(calories: 95, carbohydrates: 25, sugar: 19, fat: 0.3, protein: 0.5, fiber: 4, portionDescription: "1 medium (182 g)"),
                    confidence: 0.92,
                    visionIdentifier: "apple"
                ),
                IdentifiedFoodItem(
                    name: "Broccoli",
                    nutrition: NutritionInfo(calories: 55, carbohydrates: 11, sugar: 2.2, fat: 0.6, protein: 3.7, fiber: 5.1, portionDescription: "1 cup chopped (156 g)"),
                    confidence: 0.88,
                    visionIdentifier: "broccoli"
                ),
            ],
            image: nil,
            onLogMeal: nil
        )
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
