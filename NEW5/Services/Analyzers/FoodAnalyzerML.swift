//
//  FoodAnalyzerFinal.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 29/01/26.
// This food analyzer uses the mL model trained to recognize fruit and vegetables
//


import Foundation
import Vision
import UIKit
import CoreML

final class FoodAnalyzerML: Sendable {

    private let confidenceThreshold: Float = 0.15
    private let maxItemsPerMeal: Int = 8
    private let nutritionService: NutritionServicing

    init(nutritionService: NutritionServicing = NutritionService()) {
        self.nutritionService = nutritionService
    }

    private lazy var visionModel: VNCoreMLModel = {
        do {
            //let model = try DiabetesFoodClassifier_Final(configuration: MLModelConfiguration()).model
            let model = try DiabetesFoodClassifierPro(configuration: MLModelConfiguration()).model
            return try VNCoreMLModel(for: model)
        } catch {
            fatalError("❌ Failed to load DiabetesFoodClassifier model: \(error)")
        }
    }()

    func analyze(image: UIImage) async throws -> [IdentifiedFoodItem] {
        guard let cgImage = image.cgImage else {
            throw AnalyzerError.invalidImage
        }

        let threshold = confidenceThreshold
        let maxItems = maxItemsPerMeal
        let model = visionModel

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                guard let self else { return }

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                Task {
                    do {
                        let items = try await self.processObservations(
                            observations,
                            confidenceThreshold: threshold,
                            maxItems: maxItems
                        )
                        continuation.resume(returning: items)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers

    private static let excludedGenericIds: Set<String> = [
        "food", "fruit", "berry", "vegetable", "dessert", "citrus_fruit"
    ]

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
