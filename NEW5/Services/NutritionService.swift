
//
//  NutritionService.swift
//  Foodabase
//
//  Created by Michela D'Auria on 28/01/26.
//
import Foundation

protocol NutritionServicing: Sendable {
    func searchFoods(query: String) async throws -> [Food]
}

final class NutritionService: NutritionServicing {
    private let apiKey = "YV566JdXzsDhZ8yA4CFya6DD2wTc3q8a9IRKKrJm"
    private let baseURL = "https://api.nal.usda.gov/fdc/v1/foods/search"

    func searchFoods(query: String) async throws -> [Food] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "25"),
            URLQueryItem(name: "api_key", value: apiKey),
        ]

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(
            FoodSearchResponse.self,
            from: data
        )
        return decoded.foods
    }
}
