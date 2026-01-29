//
//  NutritionInfo.swift
//  NEW5
//
//  Diabetes-focused nutrition data: sugar, carbs, fat, calories, portion.
//

import Foundation

struct NutritionInfo: Sendable {
    var calories: Double
    var carbohydrates: Double   // g
    var sugar: Double           // g — primary focus for diabetes
    var fat: Double             // g
    var protein: Double
    var fiber: Double?
    var portionDescription: String  // e.g. "1 medium (182 g)", "1 cup chopped"

    var sugarPerServingFormatted: String {
        String(format: "%.1f g", sugar)
    }

    var carbsPerServingFormatted: String {
        String(format: "%.1f g", carbohydrates)
    }

    var fatPerServingFormatted: String {
        String(format: "%.1f g", fat)
    }

    var caloriesFormatted: String {
        String(format: "%.0f kcal", calories)
    }
}
