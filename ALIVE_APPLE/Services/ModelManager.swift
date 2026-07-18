import Foundation
import Observation

/// Manages MLX model lifecycle: load, unload, discover, validate, import.
/// v1 simplified: single model at a time (text or vision, never both).
actor ModelManager {
    
    // MARK: - Configuration
    
    private let maxMemoryBudgetGB: Float = 5.5
    private let idleUnloadSeconds: TimeInterval = 300
    
    // MARK: - State
    
    private var loadedModel: ModelConfig?
    private var idleTimer: Task<Void, Never>?
    private var currentMemoryUsageGB: Float = 0
    private let engine: InferenceEngine
    
    init(engine: InferenceEngine) {
        self.engine = engine
    }
    
    private var modelsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("Models", isDirectory: true)
    }
    
    // MARK: - Model Loading
    
    /// Ensure a specific model is loaded (text or vision).
    /// Automatically unloads any currently loaded model to free memory.
    func ensureModelLoaded(_ config: ModelConfig) async throws -> ModelConfig {
        // Already loaded? Return it
        if loadedModel?.id == config.id, await engine.isLoaded {
            return config
        }
        
        // Check memory budget
        let neededGB = Float(config.fileSizeBytes) / 1e9
        guard neededGB <= maxMemoryBudgetGB else {
            throw ModelError.insufficientMemory(needed: neededGB, available: maxMemoryBudgetGB)
        }
        
        // Unload current model if different
        if loadedModel != nil {
            unloadCurrentModel()
            try await Task.sleep(for: .seconds(0.3))
        }
        
        // Delegate loading to InferenceEngine
        let startTime = Date()
        try await engine.loadModel(config)
        let elapsed = Date().timeIntervalSince(startTime)
        
        loadedModel = config
        currentMemoryUsageGB = neededGB
        
        print("[ModelManager] Loaded \(config.name) (\(config.formattedSize)) in \(String(format: "%.2f", elapsed))s")
        resetIdleTimer()
        
        return config
    }
    
    func unloadCurrentModel() {
        guard let model = loadedModel else { return }
        let freedGB = Float(model.fileSizeBytes) / 1e9
        currentMemoryUsageGB -= freedGB
        loadedModel = nil
        idleTimer?.cancel()
        Task { await engine.unloadModel() }
        print("[ModelManager] Unloaded \(model.name)")
    }
    
    // MARK: - Memory Budget
    
    func canLoadModel(sizeGB: Float) -> Bool {
        sizeGB <= maxMemoryBudgetGB
    }
    
    func memoryUsage() -> Float {
        currentMemoryUsageGB
    }
    
    var memoryBudgetGB: Float { maxMemoryBudgetGB }
    
    // MARK: - Model Discovery (MLX directories)
    
    /// Scan for available MLX model directories in the app sandbox.
    /// MLX models are directories containing safetensors + config.json.
    func discoverModels() -> [ModelConfig] {
        var discovered: [ModelConfig] = []
        
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            return discovered
        }
        
        for template in ModelConfig.allModels {
            let modelDir = modelsDirectory.appendingPathComponent(template.directoryName, isDirectory: true)
            if isValidMLXModelDirectory(modelDir) {
                var config = template
                let actualSize = directorySize(modelDir)
                config = ModelConfig(
                    id: template.id,
                    name: template.name,
                    directoryName: template.directoryName,
                    fileSizeBytes: actualSize > 0 ? actualSize : template.fileSizeBytes,
                    parameterCount: template.parameterCount,
                    quant: template.quant,
                    modelType: template.modelType,
                    tier: template.tier,
                    contextSize: template.contextSize,
                    isLoaded: loadedModel?.id == template.id
                )
                discovered.append(config)
            }
        }
        
        return discovered
    }
    
    /// Check if a directory is a valid MLX model directory.
    private func isValidMLXModelDirectory(_ dir: URL) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        
        // Must contain at least one .safetensors file and a config.json
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else {
            return false
        }
        
        let hasSafetensors = contents.contains { $0.hasSuffix(".safetensors") }
        let hasConfig = contents.contains { $0 == "config.json" }
        return hasSafetensors && hasConfig
    }
    
    /// Calculate total size of a directory.
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
    
    // MARK: - Model Validation
    
    /// Validate a model directory or file before import.
    func validateModel(at url: URL) -> Bool {
        // Check if it's a directory (MLX model) or single file
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return isValidMLXModelDirectory(url)
        }
        
        // Single file — check size range
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64 else {
            return false
        }
        
        let sizeGB = Double(fileSize) / 1e9
        return sizeGB >= 0.1 && sizeGB <= 6.0
    }
    
    // MARK: - Import
    
    /// Import an MLX model directory from external URL to app sandbox.
    func importModel(from sourceURL: URL, directoryName: String) async throws {
        try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        let destDir = modelsDirectory.appendingPathComponent(directoryName, isDirectory: true)
        
        // Remove existing if present
        if FileManager.default.fileExists(atPath: destDir.path) {
            try FileManager.default.removeItem(at: destDir)
        }
        
        // Copy directory
        try FileManager.default.copyItem(at: sourceURL, to: destDir)
        
        print("[ModelManager] Imported \(directoryName) to Models directory")
    }
    
    /// Import a single safetensors file (legacy / simple import)
    func importFile(from sourceURL: URL, fileName: String) async throws {
        try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        let destURL = modelsDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        print("[ModelManager] Imported \(fileName)")
    }
    
    // MARK: - Idle Timer
    
    private func resetIdleTimer() {
        idleTimer?.cancel()
        idleTimer = Task {
            try? await Task.sleep(for: .seconds(idleUnloadSeconds))
            guard !Task.isCancelled else { return }
            print("[ModelManager] Idle timeout — unloading model")
            unloadCurrentModel()
        }
    }
}

// MARK: - Errors

enum ModelError: LocalizedError, Sendable {
    case noModelForTier(RoutingTier)
    case insufficientMemory(needed: Float, available: Float)
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noModelForTier(let tier):
            return "No model available for \(tier.label) tier"
        case .insufficientMemory(let needed, let available):
            return "Need \(String(format: "%.1f", needed))GB but only \(String(format: "%.1f", available))GB available"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        }
    }
}
