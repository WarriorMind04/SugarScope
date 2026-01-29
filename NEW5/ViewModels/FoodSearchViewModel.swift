//
//  FoodSearchViewModel.swift
//  Foodabase
//
//  Created by Michela D'Auria on 28/01/26.
//

import Combine
import SwiftUI

@MainActor
final class FoodSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Food] = []
    @Published var monitoredFoods: [Food] = []
    @Published var isLoading = false

    private let service: NutritionServicing
    init(service: NutritionServicing) { self.service = service }

    // Totali per il diario giornaliero
    var totalNetCarbs: Double { monitoredFoods.reduce(0) { $0 + $1.netCarbs } }
    var totalSugars: Double { monitoredFoods.reduce(0) { $0 + $1.sugars } }
    var totalFiber: Double { monitoredFoods.reduce(0) { $0 + $1.fiber } }
    var totalProteins: Double { monitoredFoods.reduce(0) { $0 + $1.proteins } }
    var totalFats: Double { monitoredFoods.reduce(0) { $0 + $1.fats } }

    func performSearch() async {
        guard !searchText.isEmpty else { return }
        isLoading = true
        searchResults =
            (try? await service.searchFoods(query: searchText)) ?? []
        isLoading = false
    }

    func addFood(_ food: Food) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            monitoredFoods.insert(food, at: 0)
            searchText = ""
            searchResults = []
        }
    }

    func removeFood(at offsets: IndexSet) {
        monitoredFoods.remove(atOffsets: offsets)
    }
}
