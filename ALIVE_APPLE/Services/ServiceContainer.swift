import Foundation
import Observation

/// Shared service container — v1 with memory/thermal gates.
@MainActor
@Observable
final class ServiceContainer {
    let inferenceEngine = InferenceEngine()
    let modelManager = ModelManager(engine: InferenceEngine())
    let visionService = VisionService()
    let usbImportService = USBImportService()
    let memoryMonitor = MemoryMonitor()
    let thermalMonitor = ThermalMonitor()
    
    /// Shared model state
    var loadedModel: ModelConfig?
    var isModelLoaded: Bool { loadedModel != nil }
    var isLoading: Bool = false
    
    /// Load the Fast tier text model (Phi-4 Mini).
    /// Enforces memory and thermal gates before loading.
    func ensureTextModelLoaded() async throws -> ModelConfig {
        guard let config = RoutingTier.fast.textModel else {
            throw ModelError.noModelForTier(.fast)
        }
        
        // Memory gate
        guard memoryMonitor.currentPressure != .critical else {
            throw ModelError.insufficientMemory(needed: 3.0, available: 0)
        }
        
        if loadedModel?.id == config.id, inferenceEngine.isLoaded {
            return config
        }
        
        if inferenceEngine.isLoaded {
            inferenceEngine.unloadModel()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await inferenceEngine.loadModel(config)
        loadedModel = config
        return config
    }
    
    /// Load the Fast tier vision model (SmolVLM2).
    func ensureVisionModelLoaded() async throws -> ModelConfig {
        guard let config = RoutingTier.fast.visionModel else {
            throw ModelError.noModelForTier(.fast)
        }
        
        guard memoryMonitor.currentPressure != .critical else {
            throw ModelError.insufficientMemory(needed: 2.0, available: 0)
        }
        
        if loadedModel?.id == config.id, inferenceEngine.isLoaded {
            return config
        }
        
        if inferenceEngine.isLoaded {
            inferenceEngine.unloadModel()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await inferenceEngine.loadModel(config)
        loadedModel = config
        return config
    }
    
    /// Thermal gate: returns false if inference should be paused.
    var canRunInference: Bool {
        thermalMonitor.currentState != .critical && thermalMonitor.currentState != .serious
    }
    
    /// Memory check: returns true if there's room for another model.
    var hasMemoryHeadroom: Bool {
        memoryMonitor.currentPressure != .critical && memoryMonitor.currentPressure != .warning
    }
    
    func unloadModel() {
        inferenceEngine.unloadModel()
        loadedModel = nil
    }
}
