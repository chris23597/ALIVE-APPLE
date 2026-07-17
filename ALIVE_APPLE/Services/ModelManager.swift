import Foundation

/// Manages model lifecycle: load, unload, discover, validate
actor ModelManager {
    
    // MARK: - Configuration
    
    private let maxMemoryBudgetGB: Float = 5.5
    private let idleUnloadSeconds: TimeInterval = 300  // 5 minutes
    
    // MARK: - State
    
    private var loadedTextModel: ModelConfig?
    private var loadedVisionModel: ModelConfig?
    private var idleTimer: Task<Void, Never>?
    private var currentMemoryUsageGB: Float = 0
    
    private var modelsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("Models", isDirectory: true)
    }
    
    // MARK: - Model Loading
    
    /// Ensure a text model is loaded for the given tier
    func ensureTextModelLoaded(tier: RoutingTier) async throws -> ModelConfig {
        guard var config = tier.textModel else {
            throw ModelError.noModelForTier(tier)
        }
        
        // Already loaded? Return it
        if loadedTextModel?.id == config.id {
            return config
        }
        
        // Need to swap — check memory
        let neededGB = Float(config.fileSizeBytes) / 1e9
        let visionGB = loadedVisionModel.map { Float($0.fileSizeBytes) / 1e9 } ?? 0
        
        if neededGB + visionGB > maxMemoryBudgetGB {
            // Try unloading vision first
            if loadedVisionModel != nil {
                unloadVisionModel()
                try await Task.sleep(for: .seconds(0.5))
            }
            if neededGB > maxMemoryBudgetGB {
                throw ModelError.insufficientMemory(needed: neededGB, available: maxMemoryBudgetGB)
            }
        }
        
        // Unload current text model
        if loadedTextModel != nil {
            unloadTextModel()
        }
        
        // Load new model — track load time
        let startTime = Date()
        loadedTextModel = config
        currentMemoryUsageGB += neededGB
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Update config with measured load time
        config = ModelConfig(
            id: config.id,
            name: config.name,
            fileName: config.fileName,
            fileSizeBytes: config.fileSizeBytes,
            parameterCount: config.parameterCount,
            quant: config.quant,
            modelType: config.modelType,
            tier: config.tier,
            contextSize: config.contextSize,
            isLoaded: true,
            loadTimeSeconds: elapsed
        )
        loadedTextModel = config
        
        print("[ModelManager] Loaded text model: \(config.name) (\(config.formattedSize)) in \(String(format: "%.2f", elapsed))s")
        resetIdleTimer()
        
        return config
    }
    
    /// Ensure a vision model is loaded for the given tier
    func ensureVisionModelLoaded(tier: RoutingTier) async throws -> ModelConfig {
        guard var config = tier.visionModel else {
            throw ModelError.noVLMForTier(tier)
        }
        
        if loadedVisionModel?.id == config.id {
            return config
        }
        
        let neededGB = Float(config.fileSizeBytes) / 1e9
        let textGB = loadedTextModel.map { Float($0.fileSizeBytes) / 1e9 } ?? 0
        
        // Fast text + moderate vision = tight (~7.8GB)
        if neededGB + textGB > maxMemoryBudgetGB {
            // Keep fast text, load requested vision
            if neededGB + 2.8 > maxMemoryBudgetGB {
                // Even with fast text, it's tight — unload text to be safe
                unloadTextModel()
            }
        }
        
        if loadedVisionModel != nil {
            unloadVisionModel()
        }
        
        // Load new model — track load time
        let startTime = Date()
        loadedVisionModel = config
        currentMemoryUsageGB += neededGB
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Update config with measured load time
        config = ModelConfig(
            id: config.id,
            name: config.name,
            fileName: config.fileName,
            fileSizeBytes: config.fileSizeBytes,
            parameterCount: config.parameterCount,
            quant: config.quant,
            modelType: config.modelType,
            tier: config.tier,
            contextSize: config.contextSize,
            isLoaded: true,
            loadTimeSeconds: elapsed
        )
        loadedVisionModel = config
        
        print("[ModelManager] Loaded vision model: \(config.name) (\(config.formattedSize)) in \(String(format: "%.2f", elapsed))s")
        resetIdleTimer()
        
        return config
    }
    
    // MARK: - Model Unloading
    
    func unloadTextModel() {
        guard let model = loadedTextModel else { return }
        let freedGB = Float(model.fileSizeBytes) / 1e9
        currentMemoryUsageGB -= freedGB
        loadedTextModel = nil
        print("[ModelManager] Unloaded text model: \(model.name)")
    }
    
    func unloadVisionModel() {
        guard let model = loadedVisionModel else { return }
        let freedGB = Float(model.fileSizeBytes) / 1e9
        currentMemoryUsageGB -= freedGB
        loadedVisionModel = nil
        print("[ModelManager] Unloaded vision model: \(model.name)")
    }
    
    func unloadAll() {
        unloadTextModel()
        unloadVisionModel()
        idleTimer?.cancel()
        print("[ModelManager] All models unloaded")
    }
    
    // MARK: - Memory Budget
    
    func canLoadModel(sizeGB: Float) -> Bool {
        let current = loadedTextModel.map { Float($0.fileSizeBytes) / 1e9 } ?? 0
        let vision = loadedVisionModel.map { Float($0.fileSizeBytes) / 1e9 } ?? 0
        return current + vision + sizeGB <= maxMemoryBudgetGB
    }
    
    func memoryUsage() -> Float {
        currentMemoryUsageGB
    }
    
    // MARK: - Model Discovery
    
    /// Scan for available models in the app sandbox
    func discoverModels() -> [ModelConfig] {
        var discovered: [ModelConfig] = []
        
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            return discovered
        }
        
        for template in ModelConfig.allModels {
            let fileURL = modelsDirectory.appendingPathComponent(template.fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                var config = template
                // Update with actual file size
                if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
                    let actualSize = (attrs[.size] as? Int64) ?? template.fileSizeBytes
                    config = ModelConfig(
                        id: template.id,
                        name: template.name,
                        fileName: template.fileName,
                        fileSizeBytes: actualSize,
                        parameterCount: template.parameterCount,
                        quant: template.quant,
                        modelType: template.modelType,
                        tier: template.tier,
                        contextSize: template.contextSize,
                        isLoaded: isModelLoaded(template.id),
                        loadTimeSeconds: nil
                    )
                }
                discovered.append(config)
            }
        }
        
        return discovered
    }
    
    /// Check if a model is currently loaded
    func isModelLoaded(_ modelId: String) -> Bool {
        loadedTextModel?.id == modelId || loadedVisionModel?.id == modelId
    }
    
    // MARK: - Model Validation
    
    /// Validate a model file before import
    func validateModelFile(url: URL) -> Bool {
        // Check extension
        let validExtensions = ["gguf", "mlx", "mlmodelc"]
        guard validExtensions.contains(url.pathExtension.lowercased()) else {
            return false
        }
        
        // Check size range (500MB - 6GB)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64 else {
            return false
        }
        
        let sizeGB = Double(fileSize) / 1e9
        guard sizeGB >= 0.5 && sizeGB <= 6.0 else {
            return false
        }
        
        // For GGUF: validate magic bytes
        if url.pathExtension.lowercased() == "gguf" {
            return validateGGUFHeader(url: url)
        }
        
        return true
    }
    
    private func validateGGUFHeader(url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer { try? handle.close() }
        
        guard let data = try? handle.read(upToCount: 4),
              data.count == 4 else {
            return false
        }
        
        // GGUF magic: 0x47 0x47 0x55 0x46 ("GGUF")
        return data[0] == 0x47 && data[1] == 0x47 && data[2] == 0x55 && data[3] == 0x46
    }
    
    // MARK: - Import
    
    /// Import a model from external URL to app sandbox
    func importModel(from sourceURL: URL, config: ModelConfig) async throws {
        // Create models directory if needed
        try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        let destinationURL = modelsDirectory.appendingPathComponent(config.fileName)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        // Copy file
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        print("[ModelManager] Imported \(config.fileName) to Models directory")
    }
    
    // MARK: - Idle Timer
    
    private func resetIdleTimer() {
        idleTimer?.cancel()
        idleTimer = Task {
            try? await Task.sleep(for: .seconds(idleUnloadSeconds))
            guard !Task.isCancelled else { return }
            print("[ModelManager] Idle timeout — unloading moderate models")
            if loadedTextModel?.tier == .moderate {
                unloadTextModel()
            }
            if loadedVisionModel?.tier == .moderate {
                unloadVisionModel()
            }
        }
    }
}

// MARK: - Errors

enum ModelError: LocalizedError {
    case noModelForTier(RoutingTier)
    case noVLMForTier(RoutingTier)
    case insufficientMemory(needed: Float, available: Float)
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noModelForTier(let tier):
            return "No text model available for \(tier.label) tier"
        case .noVLMForTier(let tier):
            return "No vision model available for \(tier.label) tier"
        case .insufficientMemory(let needed, let available):
            return "Need \(String(format: "%.1f", needed))GB but only \(String(format: "%.1f", available))GB available"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        }
    }
}
