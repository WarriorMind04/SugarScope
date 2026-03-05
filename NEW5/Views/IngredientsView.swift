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
        VStack(spacing: 0) {
            topBar

            ZStack {
                Color(hex: "f0f4f8").ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if ingredients.isEmpty {
                    emptyView
                } else {
                    ingredientsList
                }
            }
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
        .task { await loadIngredients() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ingredients")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "94a3b8"))
                    .textCase(.uppercase)
                    .kerning(0.8)
                Text(foodItem.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0d1b2a"))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "64748b"))
                    .padding(10)
                    .background(Color(hex: "e2e8f0"))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(hex: "f0f4f8"))
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color(hex: "3b82f6"))
            Text("Loading ingredients…")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "64748b"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color(hex: "f97316"))

            VStack(spacing: 6) {
                Text("Something went wrong")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "64748b"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                Task { await loadIngredients() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "3b82f6"))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(Color(hex: "3b82f6").opacity(0.4))
            Text("No ingredients found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "64748b"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ingredients List

    private var ingredientsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                // Count badge
                HStack {
                    Text("\(ingredients.count) ingredient\(ingredients.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "3b82f6"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(hex: "3b82f6").opacity(0.1))
                        .clipShape(Capsule())
                    Spacer()
                }

                // Rows
                VStack(spacing: 0) {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                        HStack(spacing: 14) {
                            // Number circle
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "3b82f6"))
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "3b82f6").opacity(0.1))
                                .clipShape(Circle())

                            Text(ingredient)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "0d1b2a"))
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(index + 1). \(ingredient)")

                        if index < ingredients.count - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Load

    private func loadIngredients() async {
        isLoading = true
        errorMessage = nil
        do {
            ingredients = try await apiAnalyzer.getIngredients(for: foodItem.name)
        } catch AnalyzerError.foodNotFound {
            errorMessage = "Food not found in database"
        } catch AnalyzerError.noIngredientsAvailable {
            errorMessage = "No ingredients available for this food"
        } catch {
            errorMessage = "Could not load ingredients. Please check your internet connection."
        }
        isLoading = false
    }
}

