//
//  RemindersView.swift
//  NEW5
//
//  Configure smart reminders: medication, glucose checks, meal times.
//

import SwiftUI
import SwiftData
import UserNotifications

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Query private var reminderConfigs: [ReminderConfig]

    @State private var showAddMed = false
    @State private var showAddGlucose = false
    @State private var showAddMeal = false
    @State private var notifAuthorized = false

    private var gc: [ReminderConfig] { reminderConfigs.filter { $0.type == ReminderConfig.typeGlucose } }
    private var mc: [ReminderConfig] { reminderConfigs.filter { $0.type == ReminderConfig.typeMeal } }

    var body: some View {
        List {
            Section {
                Toggle("Notifications", isOn: $notifAuthorized)
                    .onChange(of: notifAuthorized) { _, on in
                        if on { Task { await requestNotifs() } }
                        else { ReminderNotificationService.shared.cancelAll() }
                    }
            } header: {
                Text("Smart reminders")
            } footer: {
                Text("Reminders are sent to your iPhone and Apple Watch.")
            }

            Section("Medications") {
                ForEach(medications) { m in
                    MedicationRow(medication: m, onDelete: { deleteMed(m) })
                }
                Button("Add medication") { showAddMed = true }
            }

            Section("Blood glucose checks") {
                ForEach(gc) { r in
                    ReminderConfigRow(config: r, onDelete: { deleteConfig(r) })
                }
                Button("Add glucose reminder") { showAddGlucose = true }
            }

            Section("Meal times") {
                ForEach(mc) { r in
                    ReminderConfigRow(config: r, onDelete: { deleteConfig(r) })
                }
                Button("Add meal reminder") { showAddMeal = true }
            }
        }
        .navigationTitle("Reminders")
        .onAppear { Task { await checkNotifStatus() } }
        .onChange(of: medications.count) { _, _ in reschedule() }
        .onChange(of: reminderConfigs.count) { _, _ in reschedule() }
        .sheet(isPresented: $showAddMed) { AddMedicationSheet(onSave: { addMed($0); showAddMed = false }) }
        .sheet(isPresented: $showAddGlucose) { AddReminderSheet(type: ReminderConfig.typeGlucose, defaultLabel: "Check blood sugar", onSave: { addConfig($0); showAddGlucose = false }) }
        .sheet(isPresented: $showAddMeal) { AddReminderSheet(type: ReminderConfig.typeMeal, defaultLabel: "Meal time", onSave: { addConfig($0); showAddMeal = false }) }
    }

    private func requestNotifs() async {
        notifAuthorized = await ReminderNotificationService.shared.requestAuthorization()
        if notifAuthorized { reschedule() }
    }

    private func checkNotifStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notifAuthorized = settings.authorizationStatus == .authorized
        }
    }

    private func reschedule() {
        guard notifAuthorized else { return }
        ReminderNotificationService.shared.schedule(
            medications: medications,
            glucoseConfigs: gc,
            mealConfigs: mc
        )
    }

    private func addMed(_ m: Medication) {
        modelContext.insert(m)
        try? modelContext.save()
    }

    private func deleteMed(_ m: Medication) {
        modelContext.delete(m)
        try? modelContext.save()
    }

    private func addConfig(_ r: ReminderConfig) {
        modelContext.insert(r)
        try? modelContext.save()
    }

    private func deleteConfig(_ r: ReminderConfig) {
        modelContext.delete(r)
        try? modelContext.save()
    }
}

private struct MedicationRow: View {
    let medication: Medication
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name).font(.headline)
                if let d = medication.dose, !d.isEmpty { Text(d).font(.caption).foregroundStyle(.secondary) }
                if !medication.reminderTimes.isEmpty {
                    Text(medication.reminderTimes.sorted().joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
        }
    }
}

private struct ReminderConfigRow: View {
    let config: ReminderConfig
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(config.label ?? config.type).font(.headline)
                Text(config.times.sorted().joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
        }
    }
}

private struct AddMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dose = ""
    @State private var times: [String] = []
    @State private var newTime = ""
    let onSave: (Medication) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Dose (optional)", text: $dose)
                Section("Reminder times (HH:mm)") {
                    ForEach(times, id: \.self) { t in
                        HStack {
                            Text(t)
                            Spacer()
                            Button("Remove") { times.removeAll { $0 == t } }
                        }
                    }
                    HStack {
                        TextField("08:00", text: $newTime)
                        Button("Add") {
                            if !newTime.isEmpty { times.append(newTime); newTime = "" }
                        }
                    }
                }
            }
            .navigationTitle("Add medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let m = Medication(name: name, dose: dose.isEmpty ? nil : dose, reminderTimes: times)
                        onSave(m)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

private struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let type: String
    let defaultLabel: String
    @State private var label = ""
    @State private var times: [String] = []
    @State private var newTime = ""
    let onSave: (ReminderConfig) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label", text: $label)
                Section("Times (HH:mm)") {
                    ForEach(times, id: \.self) { t in
                        HStack {
                            Text(t)
                            Spacer()
                            Button("Remove") { times.removeAll { $0 == t } }
                        }
                    }
                    HStack {
                        TextField("08:00", text: $newTime)
                        Button("Add") {
                            if !newTime.isEmpty { times.append(newTime); newTime = "" }
                        }
                    }
                }
            }
            .navigationTitle(type == ReminderConfig.typeGlucose ? "Glucose reminder" : "Meal reminder")
            .onAppear { if label.isEmpty { label = defaultLabel } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let r = ReminderConfig(type: type, times: times, isEnabled: true, label: label.isEmpty ? nil : label)
                        onSave(r)
                    }
                    .disabled(times.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RemindersView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
