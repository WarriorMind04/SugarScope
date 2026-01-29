//
//  Components.swift
//  Foodabase
//
//  Created by Michela D'Auria on 28/01/26.
//
import SwiftUI

struct SummaryHeaderView: View {
    let netCarbs: Double
    let sugars: Double
    let proteins: Double
    let fats: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Recap")
                .font(.title2.bold())
                .foregroundColor(.secondary)

            // Griglia 2x2 per i nutrienti principali
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    summaryItem(
                        title: "Net Carbs",
                        value: netCarbs,
                        color: .blue
                    )
                    summaryItem(
                        title: "Sugars",
                        value: sugars,
                        color: .red
                    )
                }
                HStack(spacing: 10) {
                    summaryItem(
                        title: "Proteins",
                        value: proteins,
                        color: .orange
                    )
                    summaryItem(
                        title: "Fats",
                        value: fats,
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func summaryItem(
        title: String,
        value: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(.body, weight: .bold))
                .foregroundColor(.secondary)

            Text("\(value, specifier: "%.1f")g")
                .font(.headline.monospacedDigit())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct FoodRow: View {
    let food: Food
    var onAdd: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.description.capitalized)
                    .font(.headline.bold())
                    .lineLimit(2)
                Spacer()
                if let onAdd = onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Badge informativi completi
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    miniBadge(
                        value: food.netCarbs,
                        color: .blue,
                        label: "NET CARBS"
                    )
                    miniBadge(
                        value: food.sugars,
                        color: .red,
                        label: "SUGARS"
                    )
                    miniBadge(
                        value: food.proteins,
                        color: .orange,
                        label: "PROTEINS"
                    )
                    miniBadge(value: food.fats, color: .purple, label: "FATS")
                    miniBadge(value: food.fiber, color: .green, label: "FIBERS")
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func miniBadge(value: Double, color: Color, label: String)
        -> some View
    {
        Text("\(label): \(value, specifier: "%.1f")g")
            .font(.system(size: 15, weight: .black, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(color)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}
