import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Detects and imports models from USB-C drives and Files app on iOS.
///
/// Uses UIDocumentPickerViewController for iOS file access —
/// iOS doesn't expose raw mount points like `/Volumes/`.
/// The picker allows users to browse their Files app (iCloud, USB drives, local storage).
actor USBImportService {
    
    // MARK: - Configuration
    
    /// Supported model file extensions
    private let supportedExtensions = ["gguf", "mlx", "mlmodelc"]
    
    /// Maximum file size for import (6GB)
    private let maxFileSizeBytes: Int64 = 6_000_000_000
    
    /// Minimum file size (500MB — reject too-small files)
    private let minFileSizeBytes: Int64 = 500_000_000
    
    // MARK: - Import Progress
    
    private var importProgress: Double = 0
    private var totalBytesToImport: Int64 = 0
    private var bytesImported: Int64 = 0
    
    // MARK: - Model Discovery
    
    /// Scan a directory for model files.
    /// Works with any directory the user has granted access to via document picker.
    func scanForModels(in directory: URL) -> [DiscoveredModel] {
        var discovered: [DiscoveredModel] = []
        
        // Check if directory is accessible (security-scoped resource)
        let isSecurityScoped = directory.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                directory.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return discovered
        }
        
        for case let fileURL as URL in enumerator {
            guard supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }
            
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize,
                  fileSize <= maxFileSizeBytes,
                  fileSize >= minFileSizeBytes else {
                continue
            }
            
            let model = DiscoveredModel(
                url: fileURL,
                fileName: fileURL.lastPathComponent,
                fileSize: Int64(fileSize),
                matchedConfig: matchToConfig(fileName: fileURL.lastPathComponent, fileSize: Int64(fileSize))
            )
            
            discovered.append(model)
        }
        
        return discovered
    }
    
    /// Try to match a discovered file to a known model config
    private func matchToConfig(fileName: String, fileSize: Int64) -> ModelConfig? {
        for template in ModelConfig.allModels {
            // Match by filename or model name
            let nameMatch = fileName.lowercased().contains(template.fileName.lowercased().replacingOccurrences(of: ".gguf", with: ""))
            let configMatch = fileName.lowercased().contains(template.name.lowercased().replacingOccurrences(of: " ", with: "-"))
            
            if nameMatch || configMatch {
                return template
            }
        }
        return nil
    }
    
    // MARK: - Import
    
    /// Import a single model file to app sandbox.
    /// Handles security-scoped URLs from document picker.
    func importModel(from sourceURL: URL, to modelManager: ModelManager) async throws {
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let matchedConfig = matchToConfig(
            fileName: sourceURL.lastPathComponent,
            fileSize: (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)) ?? 0
        )
        
        guard let config = matchedConfig else {
            throw USBImportError.unrecognizedModel(sourceURL.lastPathComponent)
        }
        
        // Validate the file before copying
        guard await modelManager.validateModelFile(url: sourceURL) else {
            throw USBImportError.invalidModel(sourceURL.lastPathComponent)
        }
        
        try await modelManager.importModel(from: sourceURL, config: config)
    }
    
    /// Import all discovered models with progress reporting
    func importAll(
        models: [DiscoveredModel],
        modelManager: ModelManager,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        totalBytesToImport = models.reduce(0) { $0 + $1.fileSize }
        bytesImported = 0
        
        for model in models {
            try await importModel(from: model.url, to: modelManager)
            bytesImported += model.fileSize
            let progress = Double(bytesImported) / Double(totalBytesToImport)
            onProgress(progress)
        }
    }
    
    // MARK: - URL Helpers
    
    /// Check if a URL represents a valid model file
    func isModelFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    /// Get the filename for display
    func displayName(for url: URL) -> String {
        url.lastPathComponent
    }
}

// MARK: - Document Picker (SwiftUI)

/// SwiftUI wrapper for UIDocumentPickerViewController.
/// Allows users to browse and select model files from Files app,
/// iCloud Drive, or connected USB-C drives.
struct ModelDocumentPicker: UIViewControllerRepresentable {
    
    /// Called when user selects model files
    let onPick: ([URL]) -> Void
    
    /// Content types for model files
    static var modelUTTypes: [UTType] {
        // Register GGUF as a known type, plus generic data for other formats
        let gguf = UTType(filenameExtension: "gguf") ?? .data
        let mlx = UTType(filenameExtension: "mlx") ?? .data
        let mlmodelc = UTType(filenameExtension: "mlmodelc") ?? .data
        return [gguf, mlx, mlmodelc]
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.modelUTTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        
        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled — no action needed
        }
    }
}

/// SwiftUI wrapper for directory picker (used to select a USB drive root).
struct ModelDirectoryPicker: UIViewControllerRepresentable {
    
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onPick(url)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled
        }
    }
}

// MARK: - Supporting Types

struct DiscoveredModel: Identifiable {
    let id: UUID = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64
    let matchedConfig: ModelConfig?
    
    var formattedSize: String {
        let sizeGB = Double(fileSize) / 1_000_000_000.0
        if sizeGB >= 1.0 {
            return String(format: "%.1f GB", sizeGB)
        } else {
            return String(format: "%.0f MB", sizeGB * 1000)
        }
    }
    
    var tierLabel: String {
        matchedConfig?.tier.label ?? "Unknown"
    }
}

enum USBImportError: LocalizedError {
    case unrecognizedModel(String)
    case invalidModel(String)
    case driveNotFound
    case notExFAT
    case insufficientSpace(needed: Int64, available: Int64)
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .unrecognizedModel(let name):
            return "Unrecognized model file: \(name)"
        case .invalidModel(let name):
            return "Invalid model file: \(name)"
        case .driveNotFound:
            return "No USB drive detected. Connect a USB-C drive with model files."
        case .notExFAT:
            return "Drive must be formatted as exFAT"
        case .insufficientSpace(let needed, let available):
            return "Need \(ByteCountFormatter.string(fromByteCount: needed, countStyle: .file)) but only \(ByteCountFormatter.string(fromByteCount: available, countStyle: .file)) available"
        case .accessDenied:
            return "Access to the selected file was denied"
        }
    }
}
