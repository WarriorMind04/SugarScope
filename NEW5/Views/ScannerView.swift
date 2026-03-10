import SwiftUI
import AVFoundation
import SwiftData
import PhotosUI

struct ScannerView: View {

    // MARK: - Profile / SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var reminders: [ReminderConfig]
    @Query(sort: \HealthLogEntry.timestamp, order: .reverse) private var allEntries: [HealthLogEntry]

    // MARK: - Navigation Sheets
    @State private var showProfile   = false
    @State private var showReminders = false

    // MARK: - Analysis State
    @State private var capturedImage: UIImage?
    @State private var analyzedItems: [IdentifiedFoodItem] = []
    @State private var isAnalyzing   = false
    @State private var analysisError: String?
    @State private var showResults   = false

    // MARK: - Analyzer (ML Model fixed)
    private let mlAnalyzer = FoodAnalyzerML()
    private var currentAnalyzer: any FoodAnalyzing { mlAnalyzer }

    // MARK: - Camera / Photo Picker
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Computed
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private var firstName: String {
        userProfiles.first?.firstName ?? "there"
    }

    private var todayGlucoseEntries: [HealthLogEntry] {
        let start = Calendar.current.startOfDay(for: Date())
        return allEntries.filter { $0.kind == HealthLogEntry.kindGlucose && $0.timestamp >= start }
    }

    private var latestGlucose: Double? {
        todayGlucoseEntries.first?.value
    }

    private var glucoseStatus: (label: String, color: Color) {
        guard let g = latestGlucose else { return ("No data", .gray) }
        switch g {
        case ..<70:  return ("Low", .red)
        case 70..<100: return ("In Range", Color(hex: "1a7fc1"))
        case 100..<140: return ("In Range", Color(hex: "1a7fc1"))
        case 140..<180: return ("Elevated", .orange)
        default: return ("High", .red)
        }
    }

    private var todayTotalSugar: Double {
        let start = Calendar.current.startOfDay(for: Date())
        let todayEntries = allEntries.filter { $0.timestamp >= start }
        let sugar = todayEntries.filter { $0.kind == HealthLogEntry.kindSugar }.compactMap(\.value).reduce(0, +)
        let meal  = todayEntries.filter { $0.kind == HealthLogEntry.kindMeal  }.compactMap(\.value).reduce(0, +)
        return sugar + meal
    }

    private let dailySugarLimit: Double = 25

    private var upcomingReminders: [ReminderConfig] {
        Array(reminders.prefix(3))
    }

    private var dailyInsight: String {
        if todayTotalSugar > dailySugarLimit {
            return "You've exceeded your sugar limit today. Consider a walk to help manage glucose levels."
        } else if todayTotalSugar > dailySugarLimit * 0.8 {
            return "You're close to your daily sugar limit. Choose your next meal carefully."
        } else if let g = latestGlucose, g > 140 {
            return "Your glucose is elevated. Avoid high-carb foods and stay hydrated."
        }
        return "Your glucose typically dips around 3 PM. Consider adding a small, protein-rich snack."
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 60)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    VStack(spacing: 16) {
                        glucoseCard
                        scanButton
                        insightCard
                        if !upcomingReminders.isEmpty {
                            upcomingSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(hex: "f0f4f8").ignoresSafeArea())
            .navigationDestination(isPresented: $showResults) {
                MealAnalysisViewProtTwoo(items: analyzedItems, image: capturedImage, onLogMeal: nil)
            }
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showReminders) {
                NavigationStack { SettingsView() }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    showCamera = false
                    handleImage(image)
                }
                .ignoresSafeArea()
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(todayDateString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(greeting)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0d1b2a"))
            }

            Spacer()

            HStack(spacing: 10) {
                Button { showReminders = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color(hex: "1a7fc1"))
                        .padding(10)
                        //.background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.07), radius: 4)
                }

                Button { showProfile = true } label: {
                    Group {
                        if let profile = userProfiles.first,
                           let data = profile.profileImageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(Color(hex: "1a7fc1").opacity(0.4))
                        }
                    }
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4)
                }
            }
        }
    }

    // MARK: - Glucose Card

    private var glucoseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Blood Glucose")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Spacer()
                Text(glucoseStatus.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(glucoseStatus.color)
                    .clipShape(Capsule())
            }

            if let g = latestGlucose {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(Int(g))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "0d1b2a"))
                    Text("mg/dL")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                        Text("Steady")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("No reading today")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Sugar intake (Today)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f / %.0f g", todayTotalSugar, dailySugarLimit))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(todayTotalSugar > dailySugarLimit ? .red : Color(hex: "1a7fc1"))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "1a7fc1").opacity(0.12))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(todayTotalSugar > dailySugarLimit
                                  ? Color.red
                                  : Color(hex: "1a7fc1"))
                            .frame(width: geo.size.width * min(1, todayTotalSugar / dailySugarLimit), height: 8)
                            .animation(.easeOut(duration: 0.6), value: todayTotalSugar)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        VStack(spacing: 10) {
            Button { showCamera = true } label: {
                HStack(spacing: 10) {
                    if isAnalyzing {
                        ProgressView().tint(.white)
                        Text("Analyzing…")
                    } else {
                        Image(systemName: "camera.fill")
                        Text("Scan Meal")
                    }
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1a7fc1"), Color(hex: "0d5a94")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color(hex: "1a7fc1").opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .disabled(isAnalyzing)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Choose from Photos")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1a7fc1"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "1a7fc1").opacity(0.2), lineWidth: 1.5)
                )
            }
            .disabled(isAnalyzing)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        handleImage(uiImage)
                    }
                }
            }

            if let err = analysisError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1a7fc1"))
                .padding(10)
                .background(Color(hex: "1a7fc1").opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Insight")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "1a7fc1"))
                Text(dailyInsight)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "0d1b2a").opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1a7fc1").opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Upcoming Reminders

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Spacer()
                Button { showReminders = true } label: {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "1a7fc1"))
                }
            }

            VStack(spacing: 1) {
                ForEach(upcomingReminders) { reminder in
                    ReminderRowView(reminder: reminder)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Analysis Logic

    private func handleImage(_ image: UIImage) {
        capturedImage = image
        analysisError = nil
        isAnalyzing   = true

        Task {
            do {
                let items = try await currentAnalyzer.analyze(image: image)
                await MainActor.run {
                    analyzedItems = items
                    isAnalyzing   = false
                    showResults   = true
                }
            } catch {
                logAnalysisError(error)
                await MainActor.run {
                    analysisError = userFriendlyMessage(from: error)
                    isAnalyzing   = false
                }
            }
        }
    }

    private func logAnalysisError(_ error: Error) {
        print("❌ [ScannerView] Analysis failed")
        print("➡️ Error type:", type(of: error))
        print("➡️ Description:", error.localizedDescription)
        let nsError = error as NSError
        print("➡️ Domain:", nsError.domain, "Code:", nsError.code)
    }

    private func userFriendlyMessage(from error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain { return "No internet connection. Please try again." }
        if nsError.domain.contains("ML")      { return "Image couldn't be analyzed. Try another photo." }
        return "Analysis failed. Please try again."
    }
}

// MARK: - Reminder Row

private struct ReminderRowView: View {
    let reminder: ReminderConfig

    private var timeString: String {
        guard let first = reminder.times.first else { return "—" }
        let parts = first.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return first }
        let hour = parts[0]
        let minute = parts[1]
        let ampm = hour >= 12 ? "PM" : "AM"
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", h12, minute, ampm)
    }

    private var icon: String {
        switch reminder.type {
        case ReminderConfig.typeGlucose: return "drop.fill"
        case ReminderConfig.typeMeal:    return "fork.knife"
        default:                         return "pills.fill"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString.components(separatedBy: " ").first ?? timeString)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Text(timeString.components(separatedBy: " ").last ?? "")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50, alignment: .trailing)

            Rectangle()
                .fill(Color(hex: "1a7fc1").opacity(0.15))
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.label ?? reminder.type.capitalized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                if reminder.times.count > 1 {
                    Text("\(reminder.times.count) reminders/day")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "1a7fc1").opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    ScannerView()
        .modelContainer(for: [UserProfile.self, HealthLogEntry.self, ReminderConfig.self], inMemory: true)
}
