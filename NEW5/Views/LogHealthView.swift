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
    @State private var lastLoggedLabel = ""

    private var controller: HealthLogController { HealthLogController(modelContext: modelContext) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                glucoseSection
                sugarSection
                mealSection
                medicationSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            if showLogged {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Log Health Data")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "0d1b2a"))
            .padding(.top, 8)
    }

    // MARK: - Toast

    private var toastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "22c55e"))
            Text("\(lastLoggedLabel) logged!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "0d1b2a"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .padding(.top, 60)
    }

    // MARK: - Glucose Section

    private var glucoseSection: some View {
        LogCard(
            title: "Blood Glucose",
            icon: "drop.fill",
            iconColor: Color(hex: "3b82f6"),
            iconBg: Color(hex: "3b82f6").opacity(0.1)
        ) {
            HStack(spacing: 12) {
                HStack {
                    TextField("0", text: $glucoseValue)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                        .frame(maxWidth: .infinity)
                    Text("mg/dL")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    guard let v = Double(glucoseValue.trimmingCharacters(in: .whitespaces)), v > 0 else { return }
                    let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindGlucose, value: v, unit: "mg/dL")
                    controller.addEntry(e)
                    glucoseValue = ""
                    triggerToast("Glucose")
                } label: {
                    Text("Log")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(Color(hex: "3b82f6"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(glucoseValue.isEmpty)
                .opacity(glucoseValue.isEmpty ? 0.5 : 1)
            }
        }
    }

    // MARK: - Sugar Section

    private var sugarSection: some View {
        LogCard(
            title: "Sugar Intake",
            icon: "leaf.fill",
            iconColor: Color(hex: "22c55e"),
            iconBg: Color(hex: "22c55e").opacity(0.1)
        ) {
            HStack(spacing: 12) {
                HStack {
                    TextField("0", text: $sugarValue)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                        .frame(maxWidth: .infinity)
                    Text("grams")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    guard let v = Double(sugarValue.trimmingCharacters(in: .whitespaces)), v >= 0 else { return }
                    let e = HealthLogEntry(timestamp: Date(), kind: HealthLogEntry.kindSugar, value: v, unit: "g")
                    controller.addEntry(e, dailyLimit: 25)
                    sugarValue = ""
                    triggerToast("Sugar")
                } label: {
                    Text("Log")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(Color(hex: "22c55e"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(sugarValue.isEmpty)
                .opacity(sugarValue.isEmpty ? 0.5 : 1)
            }
        }
    }

    // MARK: - Meal Section

    private var mealSection: some View {
        LogCard(
            title: "Meal",
            icon: "fork.knife",
            iconColor: Color(hex: "f97316"),
            iconBg: Color(hex: "f97316").opacity(0.1)
        ) {
            VStack(spacing: 12) {
                TextField("Description (optional)", text: $mealDesc)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(hex: "f0f4f8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    NutrientField(label: "Sugar (g)", text: $mealSugar, color: Color(hex: "f97316"))
                    NutrientField(label: "Carbs (g)", text: $mealCarbs, color: Color(hex: "3b82f6"))
                    NutrientField(label: "Cal",       text: $mealCal,   color: Color(hex: "ef4444"))
                }

                Button {
                    let sugar = Double(mealSugar.trimmingCharacters(in: .whitespaces)) ?? 0
                    let carbs = Double(mealCarbs.trimmingCharacters(in: .whitespaces)) ?? 0
                    let cal   = Double(mealCal.trimmingCharacters(in: .whitespaces))   ?? 0
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
                    triggerToast("Meal")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Meal")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "f97316"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Medication Section

    private var medicationSection: some View {
        LogCard(
            title: "Medication",
            icon: "pills.fill",
            iconColor: Color(hex: "a855f7"),
            iconBg: Color(hex: "a855f7").opacity(0.1)
        ) {
            if medications.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color(hex: "94a3b8"))
                    Text("Add medications in Reminders tab, then log here.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "64748b"))
                }
                .padding(14)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    Menu {
                        ForEach(medications.filter(\.isActive)) { m in
                            Button(m.name) { selectedMedicationId = m.id }
                        }
                    } label: {
                        HStack {
                            Text(medications.first(where: { $0.id == selectedMedicationId })?.name ?? "Select medication…")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(selectedMedicationId == nil ? Color(hex: "94a3b8") : Color(hex: "0d1b2a"))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "94a3b8"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(hex: "f0f4f8"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        guard let id = selectedMedicationId,
                              let m = medications.first(where: { $0.id == id }) else { return }
                        let e = HealthLogEntry(
                            timestamp: Date(),
                            kind: HealthLogEntry.kindMedication,
                            note: "\(m.name)\(m.dose.map { " \($0)" } ?? "")"
                        )
                        controller.addEntry(e)
                        triggerToast(m.name)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Taken")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "a855f7"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedMedicationId == nil)
                    .opacity(selectedMedicationId == nil ? 0.5 : 1)
                }
            }
        }
    }

    // MARK: - Toast helper

    private func triggerToast(_ label: String) {
        lastLoggedLabel = label
        withAnimation(.spring(response: 0.4)) { showLogged = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) { showLogged = false }
        }
    }
}

// MARK: - LogCard

private struct LogCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let iconBg: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconBg)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
            }
            content
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - NutrientField

private struct NutrientField: View {
    let label: String
    @Binding var text: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "0d1b2a"))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .textCase(.uppercase)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        LogHealthView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}



