import SwiftUI
import PhotosUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var profiles: [UserProfile]

    // Local editable copy of fields
    @State private var firstName  = ""
    @State private var lastName   = ""
    @State private var age        = 30
    @State private var weight     = 70.0
    @State private var diabetesType = "Type 1"
    @State private var usesInsulin     = false
    @State private var takesMedication = false
    @State private var usesCGM         = false
    @State private var targetLow  = 70
    @State private var targetHigh = 180

    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?

    let diabetesTypes = ["Type 1", "Type 2", "Gestational", "Other"]

    // The persisted profile (or nil if first launch)
    private var existingProfile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sugarOffWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.sugarDarkGray)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.05), radius: 4)
                        }
                        
                        Spacer()
                        
                        Text("Your Profile")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.sugarDarkGray)
                        
                        Spacer()
                        
                        // Fake hidden button for centering
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Photo Section (Minimal)
                            VStack(spacing: 12) {
                                if let profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 5)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(Color.sugarSoftGray)
                                }
                                
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Text("Edit Photo")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.sugarDarkGray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .shadow(color: .black.opacity(0.05), radius: 2)
                                }
                            }
                            
                            // Form Fields
                            VStack(alignment: .leading, spacing: 24) {
                                // Section: Personal Info
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Personal Info")
                                        .font(.headline)
                                        .foregroundColor(.sugarDarkGray)
                                    
                                    HStack(spacing: 12) {
                                        TextField("First Name", text: $firstName)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                        TextField("Last Name", text: $lastName)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Age")
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.sugarSoftGray)
                                            Stepper("Age: \(age)", value: $age, in: 1...120)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(12)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Weight (kg)")
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.sugarSoftGray)
                                            TextField("kg", value: $weight, format: .number)
                                                .keyboardType(.decimalPad)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                                
                                // Section: Diabetes Management
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Diabetes Management")
                                        .font(.headline)
                                        .foregroundColor(.sugarDarkGray)
                                    
                                    // Diabetes Type
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("What type of diabetes do you have?")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.sugarSoftGray)
                                        
                                        Picker("Type", selection: $diabetesType) {
                                            ForEach(diabetesTypes, id: \.self) { type in
                                                Text(type).tag(type)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .padding(4)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Toggles
                                    Group {
                                        Toggle("Do you use insulin?", isOn: $usesInsulin)
                                        Toggle("Do you take diabetes medication?", isOn: $takesMedication)
                                        Toggle("Do you use a CGM?", isOn: $usesCGM)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .tint(.sugarDarkGray)
                                }
                                
                                // Section: Target Range
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Target Blood Sugar Range (mg/dL)")
                                        .font(.headline)
                                        .foregroundColor(.sugarDarkGray)
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Low")
                                                .font(.caption)
                                                .foregroundColor(.sugarSoftGray)
                                            TextField("70", value: $targetLow, format: .number)
                                                .keyboardType(.numberPad)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(12)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("High")
                                                .font(.caption)
                                                .foregroundColor(.sugarSoftGray)
                                            TextField("180", value: $targetHigh, format: .number)
                                                .keyboardType(.numberPad)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                            .cleanDataStyle()
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Footer Button
                    Button {
                        saveProfile()
                        dismiss()
                    } label: {
                        Text("Save Changes")
                    }
                    .primaryButtonStyle()
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                        // Save image immediately to the persisted profile
                        let target = existingProfile ?? createProfile()
                        target.profileImageData = data
                        try? modelContext.save()
                    }
                }
            }
            .onAppear {
                // Populate local state from existing profile
                if let p = existingProfile {
                    firstName       = p.firstName
                    lastName        = p.lastName
                    age             = p.age
                    weight          = p.weight
                    diabetesType    = p.diabetesType
                    usesInsulin     = p.usesInsulin
                    takesMedication = p.takesMedication
                    usesCGM         = p.usesCGM
                    targetLow       = p.targetBloodSugarLow
                    targetHigh      = p.targetBloodSugarHigh
                    if let data = p.profileImageData, let ui = UIImage(data: data) {
                        profileImage = Image(uiImage: ui)
                    }
                }
            }
        }
    }

    @discardableResult
    private func createProfile() -> UserProfile {
        let p = UserProfile()
        modelContext.insert(p)
        return p
    }

    func saveProfile() {
        let p = existingProfile ?? createProfile()
        p.firstName            = firstName
        p.lastName             = lastName
        p.age                  = age
        p.weight               = weight
        p.diabetesType         = diabetesType
        p.usesInsulin          = usesInsulin
        p.takesMedication      = takesMedication
        p.usesCGM              = usesCGM
        p.targetBloodSugarLow  = targetLow
        p.targetBloodSugarHigh = targetHigh
        try? modelContext.save()
    }
}

#Preview {
    ProfileView()
}
