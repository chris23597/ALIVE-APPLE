import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Detects and imports MLX models from USB-C drives and Files app.
/// v1: handles MLX model directories (safetensors + config.json).
actor USBImportService {
    
    private let maxFileSizeBytes: Int64 = 6_000_000_000
    private let minFileSizeBytes: Int64 = 50_000_000
    
    // MARK: - Model Discovery
    
    /// Scan a directory for MLX model subdirectories.
    func scanForModels(in directory: URL) -> [DiscoveredModel] {
        var discovered: [DiscoveredModel] = []
        
        let isSecurityScoped = directory.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped { directory.stopAccessingSecurityScopedResource() }
        }
        
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return discovered }
        
        for url in contents {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            
            if isDir.boolValue {
                // Check for MLX model directory
                if let subContents = try? FileManager.default.contentsOfDirectory(atPath: url.path),
                   subContents.contains(where: { $0.hasSuffix(".safetensors") }),
                   subContents.contains("config.json") {
                    let size = directorySize(url)
                    let model = DiscoveredModel(
                        url: url,
                        fileName: url.lastPathComponent,
                        fileSize: size,
                        matchedConfig: matchToConfig(directoryName: url.lastPathComponent)
                    )
                    discovered.append(model)
                }
            } else if url.pathExtension.lowercased() == "safetensors" {
                // Single safetensors file
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
                let model = DiscoveredModel(
                    url: url,
                    fileName: url.lastPathComponent,
                    fileSize: size,
                    matchedConfig: nil
                )
                discovered.append(model)
            }
        }
        
        return discovered
    }
    
    private func directorySize(_ dir: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = attrs.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
    
    private func matchToConfig(directoryName: String) -> ModelConfig? {
        ModelConfig.allModels.first { $0.directoryName.lowercased() == directoryName.lowercased() }
    }
    
    // MARK: - Import
    
    /// Import a model (directory or file) to app sandbox.
    func importModel(from sourceURL: URL, to modelManager: ModelManager) async throws {
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped { sourceURL.stopAccessingSecurityScopedResource() }
        }
        
        // Determine if directory or file
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: sourceURL.path, isDirectory: &isDir), isDir.boolValue {
            let dirName = sourceURL.lastPathComponent
            try await modelManager.importModel(from: sourceURL, directoryName: dirName)
        } else {
            try await modelManager.importFile(from: sourceURL, fileName: sourceURL.lastPathComponent)
        }
    }
    
    /// Import all discovered models.
    func importAll(
        models: [DiscoveredModel],
        modelManager: ModelManager,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let total = models.count
        for (i, model) in models.enumerated() {
            try await importModel(from: model.url, to: modelManager)
            onProgress(Double(i + 1) / Double(total))
        }
    }
    
    func isModelFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "safetensors" || ext == "json"
    }
}

// MARK: - Document Picker

struct ModelDocumentPicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void
    
    static var modelUTTypes: [UTType] {
        [.folder, UTType(filenameExtension: "safetensors") ?? .data]
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.modelUTTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
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
        return sizeGB >= 1.0 ? String(format: "%.1f GB", sizeGB) : String(format: "%.0f MB", sizeGB * 1000)
    }
    
    var tierLabel: String { matchedConfig?.tier.label ?? "Unknown" }
}

enum USBImportError: LocalizedError, Sendable {
    case unrecognizedModel(String)
    case invalidModel(String)
    case driveNotFound
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .unrecognizedModel(let name): return "Unrecognized model: \(name)"
        case .invalidModel(let name): return "Invalid model: \(name)"
        case .driveNotFound: return "No USB drive detected"
        case .accessDenied: return "Access denied"
        }
    }
}
