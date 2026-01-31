//
//  FoodGroup.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 31/01/26.
//

import Foundation

struct FoodGroup: Identifiable, Sendable {
    let id: UUID
    let main: IdentifiedFoodItem
    let ingredients: [IdentifiedFoodItem]

    init(
        id: UUID = UUID(),
        main: IdentifiedFoodItem,
        ingredients: [IdentifiedFoodItem]
    ) {
        self.id = id
        self.main = main
        self.ingredients = ingredients
    }
}
