//
//  LogHealthView.swift
//  NEW5
//
//  Log blood glucose, meals, sugar intake, medications.
//

import SwiftUI
import SwiftData

struct LogHealthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]

    @State private var glucoseValue = ""
    @State private var sugarValue = ""
    @State private var mealDesc = ""
    @State private var mealSugar = ""
    @State private var mealCarbs = ""
    @State private var mealCal = ""
    @State private var selectedMedicationId: UUID?
    @State private var showLogged = false

    private var controller: HealthLogController { HealthLogController(modelContext: modelContext) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Log health data")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

                glucoseSection
                sugarSection
                mealSection
                medicationSection
            }
            .padding(20)
        }
//        .background(Color(red: 0.96, green: 0.98, blue: 0.96))
        .background {
            ZStack {
                Color.sugarOffWhite
                    .ignoresSafeArea()
                
                Image("scanbackground")
                    .resizable()
                    .scaledToFill()
//                            .ignoresSafeArea()
                
                Color.sugarOffWhite.opacity(0.5)
                    .ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Logged", isPresented: $showLogged) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your entry was saved.")
        }
    }

    private var glucoseSection: some View {
        LogSection(title: "Blood glucose", icon: "drop.fill") {
            HStack {
                TextField("mg/dL", text: $glucoseValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button("Log") {
                    guard let v = Double(glucoseValue.trimmingCharacters(in: .whitespaces)), v > 0 else { return }
                    let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindGlucose, value: v, unit: "mg/dL")
                    controller.addEntry(e)
                    glucoseValue = ""
                    showLogged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
        }
    }

    private var sugarSection: some View {
        LogSection(title: "Sugar intake", icon: "leaf.fill") {
            HStack {
                TextField("grams", text: $sugarValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button("Log") {
                    guard let v = Double(sugarValue.trimmingCharacters(in: .whitespaces)), v >= 0 else { return }
                    let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindSugar, value: v, unit: "g")
                    controller.addEntry(e)
                    sugarValue = ""
                    showLogged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
        }
    }

    private var mealSection: some View {
        LogSection(title: "Meal", icon: "fork.knife") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Description", text: $mealDesc)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Sugar (g)", text: $mealSugar).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    TextField("Carbs (g)", text: $mealCarbs).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    TextField("Cal", text: $mealCal).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
                Button("Log meal") {
                    let sugar = Double(mealSugar.trimmingCharacters(in: .whitespaces)) ?? 0
                    let carbs = Double(mealCarbs.trimmingCharacters(in: .whitespaces)) ?? 0
                    let cal = Double(mealCal.trimmingCharacters(in: .whitespaces)) ?? 0
                    let e = HealthLogEntry(
                        timestamp: Date(),
                        kind: HealthLogEntry.kindMeal,
                        value: sugar,
                        unit: "g",
                        secondaryValue: carbs,
                        note: cal > 0 ? "\(Int(cal)) kcal" : nil,
                        mealDescription: mealDesc.isEmpty ? nil : mealDesc
                    )
                    controller.addEntry(e)
                    mealDesc = ""; mealSugar = ""; mealCarbs = ""; mealCal = ""
                    showLogged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
        }
    }

    private var medicationSection: some View {
        LogSection(title: "Medication", icon: "pills.fill") {
            VStack(alignment: .leading, spacing: 10) {
                if medications.isEmpty {
                    Text("Add medications in Reminders tab, then log here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Medication", selection: $selectedMedicationId) {
                        Text("Select…").tag(nil as UUID?)
                        ForEach(medications.filter(\.isActive)) { m in
                            Text(m.name).tag(m.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Log taken") {
                        guard let id = selectedMedicationId,
                              let m = medications.first(where: { $0.id == id }) else { return }
                        let e = HealthLogEntry(
                            timestamp: Date(),
                            kind: HealthLogEntry.kindMedication,
                            note: "\(m.name)\(m.dose.map { " \($0)" } ?? "")"
                        )
                        controller.addEntry(e)
                        showLogged = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
                }
            }
        }
    }
}

private struct LogSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        LogHealthView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}



/*import SwiftUI
import SwiftData

struct LogHealthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]

    @State private var glucoseValue = ""
    @State private var sugarValue = ""
    @State private var mealDesc = ""
    @State private var mealSugar = ""
    @State private var mealCarbs = ""
    @State private var mealCal = ""
    @State private var selectedMedicationId: UUID?
    @State private var showLogged = false

    private var controller: HealthLogController { HealthLogController(modelContext: modelContext) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Log health data")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))

                glucoseSection
                sugarSection
                mealSection
                medicationSection

                // ⚠️ DEBUG — borra esta sección cuando todo funcione
                debugSection
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.98, blue: 0.96))
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Logged", isPresented: $showLogged) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your entry was saved.")
        }
    }

    // MARK: - Sections

    private var glucoseSection: some View {
        LogSection(title: "Blood glucose", icon: "drop.fill") {
            HStack {
                TextField("mg/dL", text: $glucoseValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button("Log") {
                    guard let v = Double(glucoseValue.trimmingCharacters(in: .whitespaces)), v > 0 else { return }
                    let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindGlucose, value: v, unit: "mg/dL")
                    controller.addEntry(e)
                    glucoseValue = ""
                    showLogged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
        }
    }

    private var sugarSection: some View {
        LogSection(title: "Sugar intake", icon: "leaf.fill") {
            HStack {
                TextField("grams", text: $sugarValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button("Log") {
                    guard let v = Double(sugarValue.trimmingCharacters(in: .whitespaces)), v >= 0 else { return }
                    let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindSugar, value: v, unit: "g")
                    controller.addEntry(e, dailyLimit: 25)
                    sugarValue = ""
                    showLogged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
        }
    }

    private var mealSection: some View {
        LogSection(title: "Meal", icon: "fork.knife") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Description", text: $mealDesc)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Sugar (g)", text: $mealSugar).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    TextField("Carbs (g)", text: $mealCarbs).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    TextField("Cal", text: $mealCal).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
                Button("Log meal") {
                    let sugar = Double(mealSugar.trimmingCharacters(in: .whitespaces)) ?? 0
                    let carbs = Double(mealCarbs.trimmingCharacters(in: .whitespaces)) ?? 0
                    let cal = Double(mealCal.trimmingCharacters(in: .whitespaces)) ?? 0
                    let e = HealthLogEntry(
                        timestamp: Date(),
                        kind: HealthLogEntry.kindMeal,
                        value: sugar,
                        unit: "g",
                        secondaryValue: carbs,
                        note: cal > 0 ? "\(Int(cal)) kcal" : nil,
                        mealDescription: mealDesc.isEmpty ? nil : mealDesc
                    )
                    controller.addEntry(e, dailyLimit: 25)
                    mealDesc = ""; mealSugar = ""; mealCarbs = ""; mealCal = ""
                    showLogged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            }
        }
    }

    private var medicationSection: some View {
        LogSection(title: "Medication", icon: "pills.fill") {
            VStack(alignment: .leading, spacing: 10) {
                if medications.isEmpty {
                    Text("Add medications in Reminders tab, then log here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Medication", selection: $selectedMedicationId) {
                        Text("Select…").tag(nil as UUID?)
                        ForEach(medications.filter(\.isActive)) { m in
                            Text(m.name).tag(m.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Log taken") {
                        guard let id = selectedMedicationId,
                              let m = medications.first(where: { $0.id == id }) else { return }
                        let e = HealthLogEntry(
                            timestamp: Date(),
                            kind: HealthLogEntry.kindMedication,
                            note: "\(m.name)\(m.dose.map { " \($0)" } ?? "")"
                        )
                        controller.addEntry(e)
                        showLogged = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
                }
            }
        }
    }

    // ⚠️ DEBUG — borra todo este bloque cuando las alertas funcionen correctamente
    private var debugSection: some View {
        LogSection(title: "Debug (remove before release)", icon: "ant.fill") {
            VStack(spacing: 10) {
                Button("🧹 Reset alert cache") {
                    UserDefaults.standard.removeObject(forKey: "sugarAlert_lastDate")
                    UserDefaults.standard.removeObject(forKey: "sugarAlert_lastLevel")
                    print("🧹 Anti-spam limpiado — próximo log disparará alerta")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("🚨 Test: forzar alerta exceeded") {
                    UserDefaults.standard.removeObject(forKey: "sugarAlert_lastDate")
                    UserDefaults.standard.removeObject(forKey: "sugarAlert_lastLevel")
                    SugarAlertManager.shared.evaluate(totalSugar: 30, dailyLimit: 25)
                    print("🚨 Alerta exceeded forzada")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("⚠️ Test: forzar alerta warning") {
                    UserDefaults.standard.removeObject(forKey: "sugarAlert_lastDate")
                    UserDefaults.standard.removeObject(forKey: "sugarAlert_lastLevel")
                    SugarAlertManager.shared.evaluate(totalSugar: 22, dailyLimit: 25)
                    print("⚠️ Alerta warning forzada")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.yellow.opacity(0.1))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

private struct LogSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        LogHealthView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
*/
