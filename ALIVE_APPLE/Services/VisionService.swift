import Foundation
import UIKit
import AVFoundation
import PhotosUI

/// On-device vision service: camera capture, photo picker, image preprocessing
actor VisionService {
    
    // MARK: - Image Preprocessing
    
    /// Resize and normalize an image for VLM input
    func preprocessImage(_ imageData: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        // Resize preserving aspect ratio
        let originalSize = image.size
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
        
        guard scale < 1.0 else {
            // Image is already small enough
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
    
    /// Convert image to base64 for API transport
    func imageToBase64(_ imageData: Data) -> String {
        "data:image/jpeg;base64," + imageData.base64EncodedString()
    }
    
    // MARK: - Camera Permission
    
    func requestCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Photo Library
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            return true
        }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                continuation.resume(returning: newStatus == .authorized || newStatus == .limited)
            }
        }
    }
    
    // MARK: - Analysis Pipeline
    
    /// Complete vision analysis pipeline
    func analyze(
        imageData: Data,
        prompt: String,
        tier: RoutingTier,
        engine: InferenceEngine,
        modelManager: ModelManager
    ) async throws -> String {
        // 1. Preprocess image
        guard let processedImage = preprocessImage(imageData) else {
            throw VisionError.imageProcessingFailed
        }
        
        // 2. Ensure VLM is loaded
        let model = try await modelManager.ensureVisionModelLoaded(tier: tier)
        
        // 3. Run inference
        var fullResponse = ""
        let stream = await engine.generateVision(
            image: processedImage,
            prompt: prompt,
            model: model
        )
        
        for try await token in stream {
            fullResponse += token
        }
        
        return fullResponse
    }
    
    // MARK: - Quick Analysis (Fast tier, no loading wait)
    
    func quickAnalyze(
        imageData: Data,
        engine: InferenceEngine,
        modelManager: ModelManager
    ) async throws -> String {
        return try await analyze(
            imageData: imageData,
            prompt: "Describe this image in detail. What do you see?",
            tier: .fast,
            engine: engine,
            modelManager: modelManager
        )
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

// MARK: - Camera View Representable (for SwiftUI)

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
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                parent.dismiss()
                return
            }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                    self.parent.dismiss()
                }
            }
        }
    }
}
