//
//  CameraPickerView.swift
//  NEW5
//
//  Created by José Miguel Guerrero Jiménez on 02/03/26.
//

import SwiftUI

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
