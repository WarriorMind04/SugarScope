//
//  ScanFoodView.swift
//  NEW5
//
//  Main scan UI: choose camera or photo library, capture/pick image, run analysis, show results.
//


import SwiftUI
import UIKit

struct ScanFoodView: View {
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var analyzedItems: [IdentifiedFoodItem] = []
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showResults = false
    
    // 🔥 Selector de tipo de analyzer
    @State private var analyzerType: AnalyzerType = .mlModel
    
    // Analyzers (se crean una sola vez)
    private let mlAnalyzer = FoodAnalyzerML()
    private let apiAnalyzer = FoodAnalyzer()
    
    // Analyzer actual basado en la selección
    private var currentAnalyzer: any FoodAnalyzing {
        switch analyzerType {
        case .mlModel:
            return mlAnalyzer
        case .usdaAPI:
            return apiAnalyzer
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.98, blue: 0.95),
                        Color(red: 0.88, green: 0.96, blue: 0.91)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    headerSection
                    analyzerSelector
                    scanButtons
                    if isAnalyzing { loadingSection }
                    if let err = analysisError { errorSection(err) }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SugarScope")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.22))
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(source: .camera, onImagePicked: handleImage, onCancel: { showCamera = false })
            }
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePickerView(source: .photoLibrary, onImagePicked: handleImage, onCancel: { showPhotoLibrary = false })
            }
            .navigationDestination(isPresented: $showResults) {
                MealAnalysisView(items: analyzedItems, image: capturedImage, onLogMeal: nil)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.55, blue: 0.35), Color(red: 0.15, green: 0.45, blue: 0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Scan your meal")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            Text("Take a photo or choose from library. We'll identify foods and show sugar, carbs, and calories.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
    
    // 🔥 Selector de analyzer
    private var analyzerSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis method")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.2))
            
            Picker("Analyzer", selection: $analyzerType) {
                ForEach(AnalyzerType.allCases) { type in
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.menu)
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text(analyzerType.description)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var scanButtons: some View {
        VStack(spacing: 16) {
            if cameraAvailable {
                Button {
                    showCamera = true
                    analysisError = nil
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.2, green: 0.55, blue: 0.35))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAnalyzing)
            }

            Button {
                showPhotoLibrary = true
                analysisError = nil
            } label: {
                Label("Photo Library", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.25, green: 0.5, blue: 0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isAnalyzing)
        }
        .padding(.horizontal, 8)
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
            Text("Analyzing with \(analyzerType.displayName)…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
    }

    private func errorSection(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /*private func handleImage(_ image: UIImage) {
        showCamera = false
        showPhotoLibrary = false
        capturedImage = image
        analysisError = nil
        isAnalyzing = true

        Task {
            do {
                // 🔥 Usa el analyzer seleccionado dinámicamente
                var items = try await currentAnalyzer.analyze(image: image)
                //items = await usdaService.enrich(items: items)
                await MainActor.run {
                    analyzedItems = items
                    isAnalyzing = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    analysisError = "Analysis failed with \(analyzerType.displayName). Please try another photo."
                    isAnalyzing = false
                }
            }
        }
    }*/
    
    private func handleImage(_ image: UIImage) {
        showCamera = false
        showPhotoLibrary = false
        capturedImage = image
        analysisError = nil
        isAnalyzing = true

        Task {
            do {
                let items = try await currentAnalyzer.analyze(image: image)

                await MainActor.run {
                    analyzedItems = items
                    isAnalyzing = false
                    showResults = true
                }
            } catch {
                // 🔥 LOG COMPLETO EN CONSOLA
                logAnalysisError(error)

                await MainActor.run {
                    analysisError = userFriendlyMessage(from: error)
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func logAnalysisError(_ error: Error) {
        print("❌ [ScanFoodView] Analysis failed")
        print("➡️ Error type:", type(of: error))
        print("➡️ Description:", error.localizedDescription)

        let nsError = error as NSError
        print("➡️ Domain:", nsError.domain)
        print("➡️ Code:", nsError.code)
        print("➡️ UserInfo:", nsError.userInfo)
    }
    
    private func userFriendlyMessage(from error: Error) -> String {
        let nsError = error as NSError

        // Errores de red
        if nsError.domain == NSURLErrorDomain {
            return "No internet connection. Please try again."
        }

        // Errores de modelo ML
        if nsError.domain.contains("ML") {
            return "The image could not be analyzed. Try another photo."
        }

        return "Analysis failed with \(analyzerType.displayName). Please try again."
    }
}

// 🔥 Enum para tipos de analyzer
enum AnalyzerType: String, CaseIterable, Identifiable {
    case mlModel = "ml"
    case usdaAPI = "api"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mlModel: return "ML Model"
        case .usdaAPI: return "Vision API"
        }
    }
    
    var icon: String {
        switch self {
        case .mlModel: return "cpu"
        case .usdaAPI: return "eye"
        }
    }
    
    var description: String {
        switch self {
        case .mlModel:
            return "Custom diabetes-focused model created with createML"
        case .usdaAPI:
            return "API USDA database model (requires internet)"
        }
    }
}

#Preview {
    ScanFoodView()
}
