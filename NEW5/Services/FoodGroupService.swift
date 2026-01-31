//
//  FoodGroupService.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 31/01/26.
//

import Foundation

protocol FoodGroupingServiceProtocol {
    func group(items: [IdentifiedFoodItem]) -> [FoodGroup]
}

struct FoodGroupingService: FoodGroupingServiceProtocol {

    func group(items: [IdentifiedFoodItem]) -> [FoodGroup] {
        guard items.count > 1 else {
            return items.map { FoodGroup(main: $0, ingredients: []) }
        }

        // Heurística simple:
        // El item con más calorías se asume plato principal
        let sorted = items.sorted { $0.nutrition.calories > $1.nutrition.calories }
        let main = sorted.first!
        let ingredients = Array(sorted.dropFirst())

        return [FoodGroup(main: main, ingredients: ingredients)]
    }
}
