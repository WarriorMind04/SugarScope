import SwiftUI
import PhotosUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var profiles: [UserProfile]

    @State private var firstName       = ""
    @State private var lastName        = ""
    @State private var age             = 30
    @State private var weight          = 70.0
    @State private var diabetesType    = "Type 1"
    @State private var usesInsulin     = false
    @State private var takesMedication = false
    @State private var usesCGM         = false
    @State private var targetLow       = 70
    @State private var targetHigh      = 180
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?

    let diabetesTypes = ["Type 1", "Type 2", "Gestational", "Other"]
    private var existingProfile: UserProfile? { profiles.first }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    avatarSection
                    personalInfoCard
                    diabetesCard
                    targetRangeCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }

            saveButton
        }
        .background(Color(hex: "f0f4f8").ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                    let target = existingProfile ?? createProfile()
                    target.profileImageData = data
                    try? modelContext.save()
                }
            }
        }
        .onAppear { loadProfile() }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 4)
            }
            Spacer()
            Text("Your Profile")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "0d1b2a"))
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Avatar
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "3b82f6").opacity(0.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "3b82f6").opacity(0.1))
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(Color(hex: "3b82f6"))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4)
                }
                .offset(x: 4, y: 4)
            }

            VStack(spacing: 2) {
                let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
                Text(name.isEmpty ? "Your Name" : name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "0d1b2a"))
                Text(diabetesType)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "3b82f6"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Personal Info Card
    private var personalInfoCard: some View {
        ProfileCard(title: "Personal Info", icon: "person.fill", iconColor: Color(hex: "3b82f6")) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ProfileField(label: "First Name", text: $firstName)
                    ProfileField(label: "Last Name",  text: $lastName)
                }
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("AGE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "94a3b8"))
                            .kerning(0.5)
                        HStack {
                            Button { if age > 1 { age -= 1 } } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: "3b82f6"))
                                    .frame(width: 28, height: 28)
                                    .background(Color(hex: "3b82f6").opacity(0.1))
                                    .clipShape(Circle())
                            }
                            Text("\(age)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "0d1b2a"))
                                .frame(minWidth: 30)
                            Button { if age < 120 { age += 1 } } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: "3b82f6"))
                                    .frame(width: 28, height: 28)
                                    .background(Color(hex: "3b82f6").opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "f0f4f8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("WEIGHT (KG)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "94a3b8"))
                            .kerning(0.5)
                        TextField("70", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "0d1b2a"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "f0f4f8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Diabetes Card
    private var diabetesCard: some View {
        ProfileCard(title: "Diabetes Management", icon: "cross.fill", iconColor: Color(hex: "f97316")) {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DIABETES TYPE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "94a3b8"))
                        .kerning(0.5)
                    HStack(spacing: 8) {
                        ForEach(diabetesTypes, id: \.self) { type in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { diabetesType = type }
                            } label: {
                                Text(type)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(diabetesType == type ? .white : Color(hex: "64748b"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(diabetesType == type ? Color(hex: "f97316") : Color(hex: "f0f4f8"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }

                Divider()

                VStack(spacing: 2) {
                    ProfileToggle(label: "Uses insulin", isOn: $usesInsulin, color: Color(hex: "f97316"))
                    Divider().padding(.leading, 16)
                    ProfileToggle(label: "Takes medication", isOn: $takesMedication, color: Color(hex: "f97316"))
                    Divider().padding(.leading, 16)
                    ProfileToggle(label: "Uses a CGM", isOn: $usesCGM, color: Color(hex: "f97316"))
                }
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Target Range Card
    private var targetRangeCard: some View {
        ProfileCard(title: "Target Blood Sugar", icon: "target", iconColor: Color(hex: "22c55e")) {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "e2e8f0"))
                                .frame(height: 8)
                            let total = 400.0
                            let lowFrac  = max(0, min(1, Double(targetLow)  / total))
                            let highFrac = max(0, min(1, Double(targetHigh) / total))
                            let w = geo.size.width
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "22c55e"))
                                .frame(width: max(0, (highFrac - lowFrac) * w), height: 8)
                                .offset(x: lowFrac * w)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
                    HStack {
                        Text("\(targetLow) mg/dL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "22c55e"))
                        Spacer()
                        Text("Target range")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "94a3b8"))
                        Spacer()
                        Text("\(targetHigh) mg/dL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "22c55e"))
                    }
                }
                .padding(12)
                .background(Color(hex: "f0f4f8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LOW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "94a3b8"))
                            .kerning(0.5)
                        HStack(spacing: 4) {
                            TextField("70", value: $targetLow, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "0d1b2a"))
                            Text("mg/dL")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "94a3b8"))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "f0f4f8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("HIGH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "94a3b8"))
                            .kerning(0.5)
                        HStack(spacing: 4) {
                            TextField("180", value: $targetHigh, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "0d1b2a"))
                            Text("mg/dL")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "94a3b8"))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "f0f4f8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button { saveProfile(); dismiss() } label: {
            Text("Save Changes")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "3b82f6"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "3b82f6").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(hex: "f0f4f8"))
    }

    // MARK: - Helpers
    private func loadProfile() {
        guard let p = existingProfile else { return }
        firstName = p.firstName; lastName = p.lastName; age = p.age
        weight = p.weight; diabetesType = p.diabetesType
        usesInsulin = p.usesInsulin; takesMedication = p.takesMedication
        usesCGM = p.usesCGM; targetLow = p.targetBloodSugarLow; targetHigh = p.targetBloodSugarHigh
        if let data = p.profileImageData, let ui = UIImage(data: data) { profileImage = Image(uiImage: ui) }
    }

    @discardableResult
    private func createProfile() -> UserProfile {
        let p = UserProfile(); modelContext.insert(p); return p
    }

    private func saveProfile() {
        let p = existingProfile ?? createProfile()
        p.firstName = firstName; p.lastName = lastName; p.age = age
        p.weight = weight; p.diabetesType = diabetesType
        p.usesInsulin = usesInsulin; p.takesMedication = takesMedication
        p.usesCGM = usesCGM; p.targetBloodSugarLow = targetLow; p.targetBloodSugarHigh = targetHigh
        try? modelContext.save()
    }
}

// MARK: - ProfileCard
private struct ProfileCard<Content: View>: View {
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

// MARK: - ProfileField
private struct ProfileField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "94a3b8"))
                .kerning(0.5)
            TextField(label, text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "0d1b2a"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "f0f4f8"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ProfileToggle
private struct ProfileToggle: View {
    let label: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "0d1b2a"))
        }
        .tint(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
