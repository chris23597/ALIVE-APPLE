import Foundation
import UIKit
import AVFoundation
import PhotosUI

/// On-device vision service: image preprocessing + VLM dispatch.
/// v1 simplified: single Fast tier, direct VLM analysis.
actor VisionService {
    
    // MARK: - Image Preprocessing
    
    func preprocessImage(_ imageData: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        let originalSize = image.size
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
        
        guard scale < 1.0 else {
            return imageData
        }
        
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized?.jpegData(compressionQuality: 0.85)
    }
    
    // MARK: - Camera Permission
    
    func requestCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Analysis (v1: single path)
    
    /// Analyze an image using the vision model.
    /// Returns streaming tokens via AsyncThrowingStream.
    func analyze(
        imageData: Data,
        prompt: String,
        engine: InferenceEngine
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let processed = preprocessImage(imageData) else {
                        continuation.finish(throwing: VisionError.imageProcessingFailed)
                        return
                    }
                    
                    let model = RoutingTier.fast.visionModel!
                    let stream = await engine.generateVision(
                        image: processed,
                        prompt: prompt,
                        model: model
                    )
                    
                    for try await token in stream {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors

enum VisionError: LocalizedError {
    case imageProcessingFailed
    case cameraNotAvailable
    case noVisionModel
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image for analysis"
        case .cameraNotAvailable:
            return "Camera is not available"
        case .noVisionModel:
            return "No vision model loaded"
        }
    }
}

// MARK: - Camera View (SwiftUI)

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.dismiss()
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
                DispatchQueue.main.async {
                    self.parent.dismiss()
                }
            }
        }
    }
}
