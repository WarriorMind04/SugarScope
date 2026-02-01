//
//  FoodAnalyzer.swift
//  NEW5
//
//  Uses Vision VNClassifyImageRequest to identify food, then looks up nutrition
//  from the USDA API
//


import Foundation
import Vision
import UIKit

final class FoodAnalyzer: Sendable, FoodAnalyzing {

    private let confidenceThreshold: Float = 0.15
    private let maxItemsPerMeal: Int = 8
    private let nutritionService: NutritionServicing

    init(nutritionService: NutritionServicing = NutritionService()) {
        self.nutritionService = nutritionService
    }

    func analyze(image: UIImage) async throws -> [IdentifiedFoodItem] {
        guard let cgImage = image.cgImage else {
            throw AnalyzerError.invalidImage
        }

        let threshold = confidenceThreshold
        let maxItems = maxItemsPerMeal

        return try await Task.detached(priority: .userInitiated) {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            guard let observations = request.results else {
                return []
            }

            return try await self.processObservations(
                observations,
                confidenceThreshold: threshold,
                maxItems: maxItems
            )
        }.value
    }

    // MARK: - Filters

    private static let excludedGenericIds: Set<String> = [
        "food", "fruit", "berry", "vegetable", "dessert", "citrus_fruit"
    ]

    // MARK: - USDA powered logic

    private func processObservations(
        _ observations: [VNClassificationObservation],
        confidenceThreshold: Float,
        maxItems: Int
    ) async throws -> [IdentifiedFoodItem] {

        var items: [IdentifiedFoodItem] = []
        var seen = Set<String>()

        for obs in observations where obs.confidence >= confidenceThreshold {
            let query = obs.identifier
            if seen.contains(query) { continue }
            if Self.excludedGenericIds.contains(query) { continue }

            let foods = try await nutritionService.searchFoods(query: query)
            guard let food = foods.first else { continue }

            seen.insert(query)

            items.append(
                IdentifiedFoodItem(
                    name: food.description.capitalized,
                    nutrition: food.toNutritionInfo(),
                    confidence: obs.confidence,
                    visionIdentifier: query
                )
            )

            if items.count >= maxItems { break }
        }

        if items.isEmpty, let fallback = Self.firstSpecificFood(observations) {
            let foods = try await nutritionService.searchFoods(query: fallback.identifier)
            if let food = foods.first {
                return [
                    IdentifiedFoodItem(
                        name: food.description.capitalized,
                        nutrition: food.toNutritionInfo(),
                        confidence: fallback.confidence,
                        visionIdentifier: fallback.identifier
                    )
                ]
            }
        }

        return items.sorted { $0.confidence > $1.confidence }
    }

    private static func firstSpecificFood(_ observations: [VNClassificationObservation]) -> VNClassificationObservation? {
        let allowed = ["antipasti", "salad", "sandwich", "pizza", "pasta", "rice", "bread", "cake", "cookie", "apple", "banana", "broccoli", "carrot"]
        return observations.first(where: { allowed.contains($0.identifier) && !excludedGenericIds.contains($0.identifier) })
    }
}

enum AnalyzerError: Error, Sendable {
    case invalidImage
}

extension Food {
    func toNutritionInfo() -> NutritionInfo {
        NutritionInfo(
            calories: findValue(["Energy"]),
            carbohydrates: carbs,
            sugar: sugars,
            fat: fats,
            protein: proteins,
            fiber: fiber,
            portionDescription: "100g (USDA estimate)"
        )
    }

    private func findValue(_ keywords: [String]) -> Double {
        foodNutrients.first { n in
            keywords.contains { n.nutrientName.localizedCaseInsensitiveContains($0) }
        }?.value ?? 0
    }
}
