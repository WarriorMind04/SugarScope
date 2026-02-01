//
//  SugarAlert.swift
//  SugarScopeWatch Watch App
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

import Foundation

struct SugarAlert: Identifiable {
    let id = UUID()
    let level: String
    let sugar: Double
    let limit: Double
}
