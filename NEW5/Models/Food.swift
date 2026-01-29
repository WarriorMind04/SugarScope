//
//  Food.swift
//  Foodabase
//
//  Created by Michela D'Auria on 28/01/26.
//
import Foundation

struct Food: Identifiable, Codable {
    let fdcId: Int
    var id: Int { fdcId }
    let description: String
    let foodNutrients: [Nutrient]

    struct Nutrient: Codable {
        let nutrientName: String
        let unitName: String
        let value: Double
    }

    // Helper per estrarre i valori corretti dall'API USDA
    private func findValue(_ keywords: [String]) -> Double {
        foodNutrients.first { n in
            keywords.contains { keywords in
                n.nutrientName.localizedCaseInsensitiveContains(keywords)
            }
        }?.value ?? 0
    }

    var carbs: Double { findValue(["Carbohydrate", "Carbs"]) }
    var sugars: Double { findValue(["Sugars, total", "Sugar"]) }
    var fiber: Double { findValue(["Fiber, total dietary", "Fibers"]) }
    var proteins: Double { findValue(["Protein"]) }
    var fats: Double { findValue(["Total lipid", "Fat"]) }
    var netCarbs: Double { max(0, carbs - fiber) }
}

struct FoodSearchResponse: Codable {
    let foods: [Food]
}
