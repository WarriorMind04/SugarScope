//
//  FoodAnalyzing.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

import UIKit

protocol FoodAnalyzing {
    func analyze(image: UIImage) async throws -> [IdentifiedFoodItem]
}
