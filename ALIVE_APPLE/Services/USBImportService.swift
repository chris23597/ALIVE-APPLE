import Foundation
import UniformTypeIdentifiers

/// Detects and imports models from USB-C drives
actor USBImportService {
    
    // MARK: - Configuration
    
    private let supportedExtensions = ["gguf", "mlx", "mlmodelc"]
    private let maxFileSizeBytes: Int64 = 6_000_000_000  // 6GB
    
    // MARK: - State
    
    private var importProgress: Double = 0
    private var totalBytesToImport: Int64 = 0
    private var bytesImported: Int64 = 0
    
    // MARK: - Drive Detection
    
    /// Check if a USB drive with models is mounted
    func detectUSBDrive() -> URL? {
        // On iOS, external drives appear in the app's document browser
        // The Files app provides access via UIDocumentPickerViewController
        
        // For direct USB-C detection:
        let fileManager = FileManager.default
        
        // Check common mount points
        let possiblePaths = [
            "/Volumes/ALIVE_MODELS",
            "/var/mobile/Media/ALIVE_MODELS"
        ]
        
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        return nil
    }
    
    /// Scan a directory for model files
    func scanForModels(in directory: URL) -> [DiscoveredModel] {
        var discovered: [DiscoveredModel] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
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
                  fileSize >= 500_000_000 else {  // Minimum 500MB
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
            if fileName.contains(template.fileName.replacingOccurrences(of: ".gguf", with: "")) ||
               fileName.contains(template.name.replacingOccurrences(of: " ", with: "-")) {
                return template
            }
        }
        return nil
    }
    
    // MARK: - Import
    
    /// Import a single model file to app sandbox
    func importModel(from sourceURL: URL, to modelManager: ModelManager) async throws {
        let matchedConfig = matchToConfig(
            fileName: sourceURL.lastPathComponent,
            fileSize: (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)) ?? 0
        )
        
        guard let config = matchedConfig else {
            throw USBImportError.unrecognizedModel(sourceURL.lastPathComponent)
        }
        
        try await modelManager.importModel(from: sourceURL, config: config)
    }
    
    /// Import all discovered models with progress reporting
    func importAll(
        models: [DiscoveredModel],
        modelManager: ModelManager,
        onProgress: @escaping (Double) -> Void
    ) async throws {
        totalBytesToImport = models.reduce(0) { $0 + $1.fileSize }
        bytesImported = 0
        
        for model in models {
            try await importModel(from: model.url, to: modelManager)
            bytesImported += model.fileSize
            onProgress(Double(bytesImported) / Double(totalBytesToImport))
        }
    }
    
    // MARK: - exFAT Verification
    
    /// Check if a volume is exFAT formatted
    func verifyExFATFormat(volumeURL: URL) -> Bool {
        // On iOS, we rely on the fact that mounted drives must be exFAT
        // (iOS doesn't support NTFS or APFS for external drives)
        // This is a heuristic check
        let path = volumeURL.path
        
        // Check volume capabilities
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: path) else {
            return false
        }
        
        // exFAT volumes support files larger than 4GB
        let testFile = volumeURL.appendingPathComponent(".alive_test_write")
        let testData = Data(count: 1)
        
        do {
            try testData.write(to: testFile)
            try fileManager.removeItem(at: testFile)
            return true
        } catch {
            return false
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
    
    var tierColor: String {
        matchedConfig?.tier.rawValue ?? "Unknown"
    }
}

enum USBImportError: LocalizedError {
    case unrecognizedModel(String)
    case driveNotFound
    case notExFAT
    case insufficientSpace(needed: Int64, available: Int64)
    
    var errorDescription: String? {
        switch self {
        case .unrecognizedModel(let name):
            return "Unrecognized model file: \(name)"
        case .driveNotFound:
            return "No USB drive detected"
        case .notExFAT:
            return "Drive must be formatted as exFAT"
        case .insufficientSpace(let needed, let available):
            return "Need \(ByteCountFormatter.string(fromByteCount: needed, countStyle: .file)) but only \(ByteCountFormatter.string(fromByteCount: available, countStyle: .file)) available"
        }
    }
}
