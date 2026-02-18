//
//  SugarLimitChecker.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 18/02/26.
//

import Foundation

struct SugarLimitChecker {
    static let warningThreshold: Double = 0.80

    // Claves para UserDefaults
    private static let lastAlertDateKey = "sugarAlert_lastDate"
    private static let lastAlertLevelKey = "sugarAlert_lastLevel"

    static func evaluate(currentSugar: Double, dailyLimit: Double) {
        guard dailyLimit > 0 else { return }

        let ratio = currentSugar / dailyLimit
        let level: SugarAlertLevel?

        if ratio >= 1.0 {
            level = .exceeded
        } else if ratio >= warningThreshold {
            level = .warning
        } else {
            level = nil
        }

        guard let level else { return }

        // Verificar si ya se envió esta misma alerta hoy
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let lastAlertDate = defaults.object(forKey: lastAlertDateKey) as? Date ?? .distantPast
        let lastAlertLevel = defaults.string(forKey: lastAlertLevelKey) ?? ""

        let alreadySentToday = Calendar.current.isDate(lastAlertDate, inSameDayAs: today)
        let sameOrHigherLevel = (lastAlertLevel == SugarAlertLevel.exceeded.rawValue) ||
                                (lastAlertLevel == level.rawValue)

        guard !(alreadySentToday && sameOrHigherLevel) else {
            print("ℹ️ Alerta \(level.rawValue) ya enviada hoy, omitiendo")
            return
        }

        // Guardar que ya se envió
        defaults.set(Date(), forKey: lastAlertDateKey)
        defaults.set(level.rawValue, forKey: lastAlertLevelKey)

        print("📤 Enviando alerta \(level.rawValue): \(Int(currentSugar))g / \(Int(dailyLimit))g")
        WatchBridge.shared.sendAlert(level: level, sugar: currentSugar, limit: dailyLimit)
    }
}
