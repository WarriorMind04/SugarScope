//
//  IngredientRowView.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 31/01/26.
//

import SwiftUI

struct IngredientRowView: View {
    let item: IdentifiedFoodItem

    var body: some View {
        HStack {
            Text("• \(item.name)")
                .font(.caption)
                .foregroundStyle(.primary)

            Spacer()

            Text(item.nutrition.caloriesFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
