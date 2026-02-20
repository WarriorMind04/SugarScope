import SwiftUI
import AVFoundation
import SwiftData
import PhotosUI

struct ScannerView: View {

    // MARK: - Profile / SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    // MARK: - Navigation Sheets
    @State private var showProfile   = false
    @State private var showReminders = false

    // MARK: - Analysis State
    @State private var capturedImage: UIImage?
    @State private var analyzedItems: [IdentifiedFoodItem] = []
    @State private var isAnalyzing   = false
    @State private var analysisError: String?
    @State private var showResults   = false

    // MARK: - Analyzer Selection
    @State private var analyzerType: AnalyzerType = .mlModel
    private let mlAnalyzer  = FoodAnalyzerML()
    private let apiAnalyzer = FoodAnalyzer()
    private var currentAnalyzer: any FoodAnalyzing {
        switch analyzerType {
        case .mlModel:  return mlAnalyzer
        case .usdaAPI:  return apiAnalyzer
        }
    }

    // MARK: - Camera / Photo Picker
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                //Color.sugarOffWhite.ignoresSafeArea()
                
                

                VStack(spacing: 0) {

                    // ─────────────────────────────────────────
                    // MARK: Header
                    // ─────────────────────────────────────────
                    HStack(spacing: 12) {

                        // Profile avatar (left)
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
                                        .foregroundStyle(Color.sugarSoftGray)
                                }
                            }
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4)
                        }
                        
                        // Notifications button
                        Button { showReminders = true } label: {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color(hex: "2d6a4f"))
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.06), radius: 4)
                        }

                        Spacer()

                        // Analyzer Picker (compact pill in header)
                        HStack(spacing: 4) {
                            Image(systemName: analyzerType.icon)
                                .font(.caption2.weight(.semibold))
                            Picker("", selection: $analyzerType) {
                                ForEach(AnalyzerType.allCases) { type in
                                    Text(type.shortName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "2d6a4f"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    // ─────────────────────────────────────────
                    // MARK: Hero / Tagline
                    // ─────────────────────────────────────────
//                    Spacer()

                    VStack(spacing: 20) {
                        // Big emoji
//                        Text("🍽️")
//                            .font(.system(size: 72))

                        Text("What's really\nin that bite?")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color(hex: "081c15"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .padding(.bottom, 16)

                    // Subtle hint
//                    Text("Scan or upload a photo to reveal\nsugar, carbs & glycemic impact.")
//                        .font(.footnote)
//                        .foregroundStyle(Color.sugarSoftGray)
//                        .multilineTextAlignment(.center)

                    Spacer()

                    // ─────────────────────────────────────────
                    // MARK: CTA Buttons
                    // ─────────────────────────────────────────
                    VStack(spacing: 14) {

                        // Scan Now (Camera)
                        Button { showCamera = true } label: {
                            HStack(spacing: 10) {
                                if isAnalyzing {
                                    ProgressView().tint(.white)
                                    Text("Analyzing…")
                                } else {
                                    Image(systemName: "camera.fill")
                                    Text("Scan Now")
                                }
                            }
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "2d6a4f"))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .shadow(color: Color(hex: "2d6a4f").opacity(0.35), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isAnalyzing)
                        .padding(.horizontal, 40)

                        // Choose from Photos
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Choose from Photos")
                            }
                            .font(.headline.weight(.bold))
                            .foregroundColor(Color(hex: "2d6a4f"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color(hex: "2d6a4f").opacity(0.25), lineWidth: 1.5)
                            )
                        }
                        .disabled(isAnalyzing)
                        .padding(.horizontal, 40)
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    handleImage(uiImage)
                                }
                            }
                        }

                        // Error message
                        if let err = analysisError {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.bottom, 50)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
//                    .ignoresSafeArea()
                }
            }
            // MARK: Navigation Destinations
            .navigationDestination(isPresented: $showResults) {
                MealAnalysisViewProtTwoo(items: analyzedItems, image: capturedImage, onLogMeal: nil)
            }
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showReminders) {
                NavigationStack { RemindersView() }
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
        return "Analysis failed with \(analyzerType.displayName). Please try again."
    }
}

// MARK: - Camera Picker
struct CameraPickerView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImageCaptured: onImageCaptured) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImageCaptured: (UIImage) -> Void
        init(onImageCaptured: @escaping (UIImage) -> Void) { self.onImageCaptured = onImageCaptured }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { onImageCaptured(image) }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ScannerView()
}
