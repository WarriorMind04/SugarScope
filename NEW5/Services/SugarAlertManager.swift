//
//  SugarAlertManager.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

import Foundation

final class SugarAlertManager {
    static let shared = SugarAlertManager()

    private let dailyLimit: Double = 25
    private var lastEvaluatedSugar: Double = -1

    private init() {}

    func evaluate(totalSugar: Double) {
        // Evitar enviar múltiples alertas para el mismo valor
        guard totalSugar != lastEvaluatedSugar else { return }
        lastEvaluatedSugar = totalSugar
        
        print("🍬 Evaluating sugar: \(totalSugar)g / \(dailyLimit)g")
        
        // Enviar alerta de forma asíncrona para no bloquear el UI
        DispatchQueue.global(qos: .utility).async {
            if totalSugar >= self.dailyLimit {
                WatchBridge.shared.sendAlert(
                    level: .exceeded,
                    sugar: totalSugar,
                    limit: self.dailyLimit
                )
            } else if totalSugar >= self.dailyLimit * 0.85 {
                WatchBridge.shared.sendAlert(
                    level: .warning,
                    sugar: totalSugar,
                    limit: self.dailyLimit
                )
            }
        }
        
        print("✅ Sugar evaluation dispatched")
    }
}

