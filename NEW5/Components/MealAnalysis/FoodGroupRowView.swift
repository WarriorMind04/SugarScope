//
//  FoodGroupRowView.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 31/01/26.
//

import SwiftUI

struct FoodGroupRowView: View {
    let group: FoodGroup
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(group.main.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(group.main.nutrition.caloriesFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            FoodNutritionRow(item: group.main)

            if isExpanded && !group.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ingredients")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(group.ingredients) { ingredient in
                        IngredientRowView(item: ingredient)
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.96, green: 0.98, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

/*#Preview {
    FoodGroupRowView()
}
*/
