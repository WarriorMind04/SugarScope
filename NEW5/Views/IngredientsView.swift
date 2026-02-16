//
//  IngredientsView.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 16/02/26.
//

import SwiftUI

struct IngredientsView: View {
    let foodItem: IdentifiedFoodItem
    let apiAnalyzer: FoodAnalyzer
    
    @Environment(\.dismiss) private var dismiss
    @State private var ingredients: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.98, blue: 0.96)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading ingredients...")
                            .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else if ingredients.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                            Text("No ingredients found")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1).")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                                        Text(ingredient)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(foodItem.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadIngredients()
            }
        }
    }
    
    private func loadIngredients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Aquí necesitarás agregar un método en FoodAnalyzer para obtener ingredientes
            // Por ahora simulo la llamada
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // TODO: Implementar método en apiAnalyzer para obtener ingredientes
            // let result = try await apiAnalyzer.getIngredients(for: foodItem.name)
            
            // Datos de ejemplo
            ingredients = [
                "Water",
                "Sugar",
                "Natural flavors",
                "Citric acid",
                "Sodium benzoate"
            ]
            
        } catch {
            errorMessage = "Could not load ingredients. Please check your internet connection."
        }
        
        isLoading = false
    }
}


