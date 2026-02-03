
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
    
    private let baseURL = "https://diabetes-app-backend-3mnzmkfz7-jose-miguels-projects-4169b721.vercel.app/food/search"
    

        func searchFoods(query: String) async throws -> [Food] {
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedQuery.isEmpty else { return [] }

            // Construimos la URL con query parameter
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "query", value: trimmedQuery)
            ]

            guard let url = components.url else { throw URLError(.badURL) }

            // Hacemos la request
            let (data, response) = try await URLSession.shared.data(from: url)

            // Revisamos status code
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw URLError(.badServerResponse)
            }

            // Decodificamos el JSON
            let decoded = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
            return decoded.foods
        }
}


