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

    //Here we can use the ML model of Apple
    //private let analyzer = FoodAnalyzerML()
    
    //Here we can use the API
    private let analyzer = FoodAnalyzer()
    //private let usdaService = NutritionService()

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
            Text("Take a photo or choose from library. We’ll identify foods and show sugar, carbs, and calories.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
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
            Text("Analyzing meal…")
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

    private func handleImage(_ image: UIImage) {
        showCamera = false
        showPhotoLibrary = false
        capturedImage = image
        analysisError = nil
        isAnalyzing = true

        Task {
            do {
                var items = try await analyzer.analyze(image: image)
                //items = await usdaService.enrich(items: items)
                await MainActor.run {
                    analyzedItems = items
                    isAnalyzing = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    analysisError = "Analysis failed. Please try another photo."
                    isAnalyzing = false
                }
            }
        }
    }
}

#Preview {
    ScanFoodView()
}
