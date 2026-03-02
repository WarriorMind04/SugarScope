//
//  AnalyzerType.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 02/03/26.
//

import Foundation
enum AnalyzerType: String, CaseIterable, Identifiable {
    case mlModel = "ml"
    case usdaAPI = "api"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mlModel: return "ML Model"
        case .usdaAPI: return "Vision API"
        }
    }

    var shortName: String {
        switch self {
        case .mlModel: return "ML"
        case .usdaAPI: return "API"
        }
    }
    
    var icon: String {
        switch self {
        case .mlModel: return "cpu"
        case .usdaAPI: return "eye"
        }
    }
    
    var description: String {
        switch self {
        case .mlModel:
            return "Custom diabetes-focused model created with createML"
        case .usdaAPI:
            return "API USDA database model (requires internet)"
        }
    }
}
