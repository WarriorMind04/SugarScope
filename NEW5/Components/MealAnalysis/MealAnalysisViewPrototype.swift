//
//  MealAnalysisViewPrototype.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 31/01/26.
//

import SwiftUI
import SwiftData
import UIKit

struct MealAnalysisViewPrototype: View {
    let items: [IdentifiedFoodItem]
    let image: UIImage?
    var onLogMeal: (([IdentifiedFoodItem]) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var didLog = false

    private let groupingService: FoodGroupingServiceProtocol = FoodGroupingService()

    private var foodGroups: [FoodGroup] {
        groupingService.group(items: items)
    }

    private var totalSugar: Double { items.reduce(0) { $0 + $1.nutrition.sugar } }
    private var totalCarbs: Double { items.reduce(0) { $0 + $1.nutrition.carbohydrates } }
    private var totalFat: Double { items.reduce(0) { $0 + $1.nutrition.fat } }
    private var totalCalories: Double { items.reduce(0) { $0 + $1.nutrition.calories } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerImage

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

    // MARK: - Subviews

    @ViewBuilder
    private var headerImage: some View {
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
    }

    private var foodListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identified foods")
                .font(.headline)
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

            ForEach(foodGroups) { group in
                FoodGroupRowView(group: group)
            }

            logMealButton

            disclaimer
        }
    }

    private var logMealButton: some View {
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
    }

    private var disclaimer: some View {
        Text("Nutrition and portions are estimates. Focus on sugar and carbs for diabetes management. Consult a dietitian for personalized advice.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }

    // MARK: - Actions

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
}

#Preview {
    NavigationStack {
        MealAnalysisViewPrototype(
            items: [
                IdentifiedFoodItem(
                    name: "Hamburger",
                    nutrition: NutritionInfo(calories: 520, carbohydrates: 40, sugar: 6, fat: 28, protein: 32, fiber: 3, portionDescription: "1 burger"),
                    confidence: 0.91,
                    visionIdentifier: "hamburger"
                ),
                IdentifiedFoodItem(
                    name: "Tomato",
                    nutrition: NutritionInfo(calories: 5, carbohydrates: 1, sugar: 1, fat: 0, protein: 0.2, fiber: 0.3, portionDescription: "2 slices"),
                    confidence: 0.72,
                    visionIdentifier: "tomato"
                ),
                IdentifiedFoodItem(
                    name: "Lettuce",
                    nutrition: NutritionInfo(calories: 3, carbohydrates: 0.5, sugar: 0.2, fat: 0, protein: 0.1, fiber: 0.2, portionDescription: "1 leaf"),
                    confidence: 0.69,
                    visionIdentifier: "lettuce"
                )
            ],
            image: nil
        )
    }
}
