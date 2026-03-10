//
//  RemindersView.swift
//  NEW5
//
//  Configure smart reminders: medication, glucose checks, meal times.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Query private var reminderConfigs: [ReminderConfig]

    @State private var showAddMed      = false
    @State private var showAddGlucose  = false
    @State private var showAddMeal     = false
    @State private var notifAuthorized = false

    // Info sheets
    @State private var showAbout         = false
    @State private var showPrivacy       = false
    @State private var showSupport       = false
    @State private var showSources       = false

    private var gc: [ReminderConfig] { reminderConfigs.filter { $0.type == ReminderConfig.typeGlucose } }
    private var mc: [ReminderConfig] { reminderConfigs.filter { $0.type == ReminderConfig.typeMeal } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                notificationsCard
                medicationsCard
                remindersCard
                infoCard
                appVersionFooter
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await checkNotifStatus() } }
        .onChange(of: medications.count)      { _, _ in reschedule() }
        .onChange(of: reminderConfigs.count)  { _, _ in reschedule() }
        .sheet(isPresented: $showAddMed) {
            AddMedicationSheet(onSave: { addMed($0); showAddMed = false })
        }
        .sheet(isPresented: $showAddGlucose) {
            AddReminderSheet(type: ReminderConfig.typeGlucose, defaultLabel: "Check blood sugar", onSave: { addConfig($0); showAddGlucose = false })
        }
        .sheet(isPresented: $showAddMeal) {
            AddReminderSheet(type: ReminderConfig.typeMeal, defaultLabel: "Meal time", onSave: { addConfig($0); showAddMeal = false })
        }
        .sheet(isPresented: $showAbout)   { InfoSheet(title: "About", content: aboutText) }
        .sheet(isPresented: $showPrivacy) { InfoSheet(title: "Privacy Policy", content: privacyText) }
        .sheet(isPresented: $showSupport) { InfoSheet(title: "Support", content: supportText) }
        .sheet(isPresented: $showSources) { InfoSheet(title: "Medical Sources", content: sourcesText) }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Settings")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "0d1b2a"))
            .padding(.top, 8)
    }

    // MARK: - Notifications Card

    private var notificationsCard: some View {
        SettingsCard(title: "Notifications", icon: "bell.fill", iconColor: Color(hex: "3b82f6")) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable Reminders")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                    Text("Sent to iPhone and Apple Watch")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                Spacer()
                Toggle("", isOn: $notifAuthorized)
                    .labelsHidden()
                    .tint(Color(hex: "3b82f6"))
                    .onChange(of: notifAuthorized) { _, on in
                        if on { Task { await requestNotifs() } }
                        else  { ReminderNotificationService.shared.cancelAll() }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: "f0f4f8"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Medications Card

    private var medicationsCard: some View {
        SettingsCard(title: "Medications", icon: "pills.fill", iconColor: Color(hex: "a855f7")) {
            VStack(spacing: 0) {
                if medications.isEmpty {
                    emptyState(message: "No medications added yet")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(medications.enumerated()), id: \.element.id) { i, med in
                            MedRow(medication: med, onDelete: { deleteMed(med) })
                            if i < medications.count - 1 { Divider().padding(.leading, 16) }
                        }
                    }
                    .background(Color(hex: "f0f4f8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 8)
                }

                AddButton(label: "Add medication", color: Color(hex: "a855f7")) {
                    showAddMed = true
                }
            }
        }
    }

    // MARK: - Reminders Card

    private var remindersCard: some View {
        SettingsCard(title: "Reminders", icon: "clock.fill", iconColor: Color(hex: "f97316")) {
            VStack(spacing: 12) {
                // Glucose
                VStack(alignment: .leading, spacing: 8) {
                    Label("Blood Glucose", systemImage: "drop.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "3b82f6"))
                        .textCase(.uppercase)

                    if gc.isEmpty {
                        emptyState(message: "No glucose reminders")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(gc.enumerated()), id: \.element.id) { i, r in
                                ReminderRow(config: r, onDelete: { deleteConfig(r) })
                                if i < gc.count - 1 { Divider().padding(.leading, 16) }
                            }
                        }
                        .background(Color(hex: "f0f4f8"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    AddButton(label: "Add glucose reminder", color: Color(hex: "3b82f6")) {
                        showAddGlucose = true
                    }
                }

                Divider()

                // Meal
                VStack(alignment: .leading, spacing: 8) {
                    Label("Meal Times", systemImage: "fork.knife")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "f97316"))
                        .textCase(.uppercase)

                    if mc.isEmpty {
                        emptyState(message: "No meal reminders")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(mc.enumerated()), id: \.element.id) { i, r in
                                ReminderRow(config: r, onDelete: { deleteConfig(r) })
                                if i < mc.count - 1 { Divider().padding(.leading, 16) }
                            }
                        }
                        .background(Color(hex: "f0f4f8"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    AddButton(label: "Add meal reminder", color: Color(hex: "f97316")) {
                        showAddMeal = true
                    }
                }
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        SettingsCard(title: "About & Legal", icon: "info.circle.fill", iconColor: Color(hex: "22c55e")) {
            VStack(spacing: 0) {
                ForEach(infoRows.indices, id: \.self) { i in
                    let row = infoRows[i]
                    Button { row.action() } label: {
                        HStack(spacing: 14) {
                            Image(systemName: row.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(row.color)
                                .frame(width: 30, height: 30)
                                .background(row.color.opacity(0.1))
                                .clipShape(Circle())

                            Text(row.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "0d1b2a"))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "cbd5e1"))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)

                    if i < infoRows.count - 1 { Divider().padding(.leading, 58) }
                }
            }
            .background(Color(hex: "f0f4f8"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var infoRows: [(title: String, icon: String, color: Color, action: () -> Void)] {
        [
            ("About",           "sparkles",              Color(hex: "22c55e"), { showAbout   = true }),
            ("Privacy Policy",  "lock.shield.fill",      Color(hex: "3b82f6"), { showPrivacy = true }),
            ("Support",         "questionmark.circle.fill", Color(hex: "f97316"), { showSupport = true }),
            ("Medical Sources", "cross.case.fill",        Color(hex: "ef4444"), { showSources = true }),
        ]
    }

    // MARK: - Footer

    private var appVersionFooter: some View {
        VStack(spacing: 4) {
            Text("Sugar-Lense")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "94a3b8"))
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "cbd5e1"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(Color(hex: "94a3b8"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }

    // MARK: - Logic

    private func requestNotifs() async {
        notifAuthorized = await ReminderNotificationService.shared.requestAuthorization()
        if notifAuthorized { reschedule() }
    }

    private func checkNotifStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { notifAuthorized = settings.authorizationStatus == .authorized }
    }

    private func reschedule() {
        guard notifAuthorized else { return }
        ReminderNotificationService.shared.schedule(medications: medications, glucoseConfigs: gc, mealConfigs: mc)
    }

    private func addMed(_ m: Medication)      { modelContext.insert(m); try? modelContext.save() }
    private func deleteMed(_ m: Medication)   { modelContext.delete(m); try? modelContext.save() }
    private func addConfig(_ r: ReminderConfig)   { modelContext.insert(r); try? modelContext.save() }
    private func deleteConfig(_ r: ReminderConfig){ modelContext.delete(r); try? modelContext.save() }

    // MARK: - Static Content

    private var aboutText: String {
        "Sugar Lens helps people with diabetes and those monitoring their sugar intake track blood glucose levels, log meals, and access nutritional information with AI-powered food recognition.\n\nAll data is stored securely on your device. Sugar Lens is designed to provide meaningful insights while keeping your personal health information private and safe."
    }
    private var privacyText: String {
        """
        All personal and health data entered in Sugar Lens is stored locally on your device using Apple's SwiftData framework.\n
        Sugar Lens does not collect, store, or transmit personal or health information to external servers.\n
        For meal recognition, the app may connect to the USDA FoodData Central public database to retrieve nutritional information about detected foods. These requests include only the detected food name and do not include any personal or health data.\n
        Camera and photo library access are used solely for meal scanning and food recognition. Images are processed on-device and are never stored or transmitted externally.
        """
    }
    private var supportText: String {
        """
        For help with Sugar Lens, please contact us at:\n
        support@sugarlens.app\n
        We aim to respond within 24–48 hours. For faster assistance, please include your device model and iOS version when reporting an issue.
        """
    }
    private var sourcesText: String {
        """
        Medical and nutritional information in Sugar Lens is based on publicly available resources including:\n
        • USDA FoodData Central (https://fdc.nal.usda.gov)\n
        • World Health Organization (WHO) dietary guidelines for sugar intake\n
        • American Diabetes Association standards of care\n
        Predicted glucose values are estimates based on macronutrient composition and are provided for informational purposes only. They should not replace professional medical advice, diagnosis, or treatment.
        """
    }
}

// MARK: - SettingsCard

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconColor.opacity(0.1))
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

// MARK: - AddButton

private struct AddButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - MedRow

private struct MedRow: View {
    let medication: Medication
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                if let d = medication.dose, !d.isEmpty {
                    Text(d)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
                if !medication.reminderTimes.isEmpty {
                    Text(medication.reminderTimes.sorted().joined(separator: " · "))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "94a3b8"))
                }
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - ReminderRow

private struct ReminderRow: View {
    let config: ReminderConfig
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(config.label ?? config.type.capitalized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Text(config.times.sorted().joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "94a3b8"))
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - InfoSheet

private struct InfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "64748b"))
                        .padding(10)
                        .background(Color(hex: "e2e8f0"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "1e293b"))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
    }
}

// MARK: - AddMedicationSheet (unchanged logic, restyled)

private struct AddMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name    = ""
    @State private var dose    = ""
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
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Medication(name: name, dose: dose.isEmpty ? nil : dose, reminderTimes: times))
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - AddReminderSheet (unchanged logic)

private struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let type: String
    let defaultLabel: String
    @State private var label   = ""
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
            .navigationTitle(type == ReminderConfig.typeGlucose ? "Glucose Reminder" : "Meal Reminder")
            .onAppear { if label.isEmpty { label = defaultLabel } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(ReminderConfig(type: type, times: times, isEnabled: true, label: label.isEmpty ? nil : label))
                    }
                    .disabled(times.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
