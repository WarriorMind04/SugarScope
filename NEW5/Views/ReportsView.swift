//
//  ReportsView.swift
//  NEW5
//
//  Generate and share medical reports. Data stored securely in Application Support.
//


import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var reportURL: URL?
    @State private var errorMessage: String?
    @State private var isGenerating = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                descriptionCard
                dateRangeCard
                if let err = errorMessage { errorCard(err) }
                generateButton
                if let url = reportURL { reportReadyCard(url) }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Medical Reports")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "0d1b2a"))
            .padding(.top, 8)
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "3b82f6"))
                .frame(width: 38, height: 38)
                .background(Color(hex: "3b82f6").opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("About Reports")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Text("Generate a PDF of your glucose, meals, sugar and medications for any period. Reports are stored securely on device.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "64748b"))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "3b82f6").opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Date Range Card

    private var dateRangeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "3b82f6"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "3b82f6").opacity(0.1))
                    .clipShape(Circle())
                Text("Date Range")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
            }

            VStack(spacing: 10) {
                // From
                HStack {
                    Text("From")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "64748b"))
                        .frame(width: 40, alignment: .leading)
                    Spacer()
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Color(hex: "3b82f6"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // To
                HStack {
                    Text("To")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "64748b"))
                        .frame(width: 40, alignment: .leading)
                    Spacer()
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Color(hex: "3b82f6"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Range summary pill
            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
                Text(days >= 0 ? "\(days) day\(days == 1 ? "" : "s") selected" : "Invalid range")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(days >= 0 ? Color(hex: "3b82f6") : .red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((days >= 0 ? Color(hex: "3b82f6") : Color.red).opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Error Card

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button { generateReport() } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView().tint(.white)
                    Text("Generating…")
                } else {
                    Image(systemName: "doc.badge.plus")
                    Text("Generate Report")
                }
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isGenerating || startDate > endDate
                ? Color(hex: "3b82f6").opacity(0.4)
                : Color(hex: "3b82f6")
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(hex: "3b82f6").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isGenerating || startDate > endDate)
    }

    // MARK: - Report Ready Card

    private func reportReadyCard(_ url: URL) -> some View {
        VStack(spacing: 14) {
            // Success header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "22c55e"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Report Ready")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                    Text("Your PDF has been generated successfully.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "64748b"))
                }
                Spacer()
            }

            Divider()

            ShareLink(
                item: url,
                subject: Text("SugarScope health report"),
                message: Text("Health report generated by SugarScope")
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Report")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "22c55e"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "22c55e").opacity(0.15), radius: 10, x: 0, y: 4)
    }

    // MARK: - Generate

    private func generateReport() {
        errorMessage = nil
        reportURL = nil
        isGenerating = true
        let start = startDate
        let end = endDate
        Task { @MainActor in
            do {
                let url = try MedicalReportGenerator.generate(from: start, to: end, modelContext: modelContext)
                reportURL = url
            } catch {
                errorMessage = "Could not generate report: \(error.localizedDescription)"
            }
            isGenerating = false
        }
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
    .modelContainer(for: [HealthLogEntry.self, Medication.self, ReminderConfig.self], inMemory: true)
}
