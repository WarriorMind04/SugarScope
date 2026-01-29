//
//  IdentifiedFoodItem.swift
//  NEW5
//
//  A food item identified by AI with nutrition info.
//

import Foundation

struct IdentifiedFoodItem: Identifiable, Sendable {
    let id: UUID
    let name: String
    let nutrition: NutritionInfo
    let confidence: Float       // 0...1 from Vision
    let visionIdentifier: String?  // e.g. "apple", "broccoli"

    init(
        id: UUID = UUID(),
        name: String,
        nutrition: NutritionInfo,
        confidence: Float,
        visionIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nutrition = nutrition
        self.confidence = confidence
        self.visionIdentifier = visionIdentifier
    }

    func with(nutrition: NutritionInfo) -> IdentifiedFoodItem {
        IdentifiedFoodItem(id: id, name: name, nutrition: nutrition, confidence: confidence, visionIdentifier: visionIdentifier)
    }
}
