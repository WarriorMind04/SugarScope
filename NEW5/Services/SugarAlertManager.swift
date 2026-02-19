//
//  SugarAlertManager.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 01/02/26.
//

/*import Foundation
import SwiftData

final class SugarAlertManager {
    static let shared = SugarAlertManager()

    // Umbral de advertencia: 85% del límite
    private let warningThreshold: Double = 0.85

    // Anti-spam: guardamos en UserDefaults para persistir entre sesiones
    private let defaults = UserDefaults.standard
    private let lastAlertDateKey = "sugarAlert_lastDate"
    private let lastAlertLevelKey = "sugarAlert_lastLevel"

    private init() {}

    /// Llama esto cada vez que se loguea azúcar o comida.
    /// - Parameters:
    ///   - totalSugar: gramos de azúcar consumidos hoy
    ///   - dailyLimit: límite configurado por el usuario (viene de SwiftData)
    func evaluate(totalSugar: Double, dailyLimit: Double) {
        guard dailyLimit > 0 else { return }

        let ratio = totalSugar / dailyLimit
        let level: SugarAlertLevel?

        if ratio >= 1.0 {
            level = .exceeded
        } else if ratio >= warningThreshold {
            level = .warning
        } else {
            level = nil
        }

        guard let level else {
            print("🍬 Sugar OK: \(String(format: "%.1f", totalSugar))g / \(String(format: "%.1f", dailyLimit))g")
            return
        }

        // Anti-spam: no repetir la misma alerta (o menor) en el mismo día
        if alreadySentTodayWithSameOrHigherLevel(level) {
            print("ℹ️ Alerta \(level.rawValue) ya enviada hoy, omitiendo")
            return
        }

        // Registrar que se envió
        defaults.set(Date(), forKey: lastAlertDateKey)
        defaults.set(level.rawValue, forKey: lastAlertLevelKey)

        print("🚨 Enviando alerta \(level.rawValue): \(String(format: "%.1f", totalSugar))g / \(String(format: "%.1f", dailyLimit))g")

        DispatchQueue.global(qos: .utility).async {
            WatchBridge.shared.sendAlert(level: level, sugar: totalSugar, limit: dailyLimit)
        }
    }

    // MARK: - Private

    private func alreadySentTodayWithSameOrHigherLevel(_ incoming: SugarAlertLevel) -> Bool {
        guard let lastDate = defaults.object(forKey: lastAlertDateKey) as? Date,
              Calendar.current.isDateInToday(lastDate),
              let lastLevel = defaults.string(forKey: lastAlertLevelKey) else {
            return false
        }

        // Si ya se envió "exceeded" hoy, bloquear cualquier otra
        if lastLevel == SugarAlertLevel.exceeded.rawValue { return true }

        // Si ya se envió "warning" y llega otra "warning", bloquear
        // Pero si llega "exceeded", dejar pasar (escalar)
        if lastLevel == SugarAlertLevel.warning.rawValue && incoming == .warning { return true }

        return false
    }
}

*/
import Foundation

final class SugarAlertManager {
    static let shared = SugarAlertManager()

    private let warningThreshold: Double = 0.85
    private let defaults = UserDefaults.standard

    // Claves
    private let alertsLogKey = "sugarAlert_log" // guarda array de timestamps del día

    // Configuración
    private let maxAlertsPerDay = 3
    private let minIntervalBetweenAlerts: TimeInterval = 60 * 60 * 2 // 2 horas mínimo entre alertas

    private init() {}

    func evaluate(totalSugar: Double, dailyLimit: Double) {
        guard dailyLimit > 0 else { return }

        let ratio = totalSugar / dailyLimit

        let level: SugarAlertLevel?
        if ratio >= 1.0 {
            level = .exceeded
        } else if ratio >= warningThreshold {
            level = .warning
        } else {
            cleanOldEntries() // limpiar logs de días anteriores
            return
        }

        guard let level else { return }

        // Obtener historial de alertas de hoy
        let todayAlerts = todayAlertTimestamps()

        // 1. Límite de alertas por día
        guard todayAlerts.count < maxAlertsPerDay else {
            print("ℹ️ Ya se enviaron \(maxAlertsPerDay) alertas hoy, omitiendo")
            return
        }

        // 2. Intervalo mínimo entre alertas
        if let lastAlert = todayAlerts.last {
            let elapsed = Date().timeIntervalSince(lastAlert)
            guard elapsed >= minIntervalBetweenAlerts else {
                let remaining = Int((minIntervalBetweenAlerts - elapsed) / 60)
                print("ℹ️ Próxima alerta disponible en \(remaining) min")
                return
            }
        }

        // Registrar esta alerta
        saveAlertTimestamp()

        print("📤 Enviando alerta \(level.rawValue) (\(todayAlerts.count + 1)/\(maxAlertsPerDay) hoy)")
        DispatchQueue.global(qos: .utility).async {
            WatchBridge.shared.sendAlert(level: level, sugar: totalSugar, limit: dailyLimit)
        }
    }

    // MARK: - Private

    private func todayAlertTimestamps() -> [Date] {
        let all = (defaults.array(forKey: alertsLogKey) as? [Date]) ?? []
        return all.filter { Calendar.current.isDateInToday($0) }
    }

    private func saveAlertTimestamp() {
        var all = todayAlertTimestamps() // solo guardamos las de hoy
        all.append(Date())
        defaults.set(all, forKey: alertsLogKey)
    }

    private func cleanOldEntries() {
        // Limpiar timestamps de días anteriores para no acumular basura
        let todayOnly = todayAlertTimestamps()
        defaults.set(todayOnly, forKey: alertsLogKey)
    }
}
