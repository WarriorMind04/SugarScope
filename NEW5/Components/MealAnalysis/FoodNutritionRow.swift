//
//  FoodNutritionRow.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 31/01/26.
//

import SwiftUI

struct FoodNutritionRow: View {
    let item: IdentifiedFoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.nutrition.portionDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

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
    }
}
