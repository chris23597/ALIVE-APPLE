import Foundation
import Observation

/// Shared service container — v1 simplified.
/// All ViewModels share the same service instances via @Environment.
@MainActor
@Observable
final class ServiceContainer {
    let inferenceEngine = InferenceEngine()
    let modelManager = ModelManager(engine: InferenceEngine())
    let visionService = VisionService()
    let usbImportService = USBImportService()
    
    /// Shared model state (visible across all views)
    var loadedModel: ModelConfig?
    var isModelLoaded: Bool { loadedModel != nil }
    var isLoading: Bool = false
    
    /// Load the Fast tier text model (Phi-4 Mini)
    func ensureTextModelLoaded() async throws -> ModelConfig {
        guard let config = RoutingTier.fast.textModel else {
            throw ModelError.noModelForTier(.fast)
        }
        
        // If already loaded with correct model, return it
        if loadedModel?.id == config.id, inferenceEngine.isLoaded {
            return config
        }
        
        // Unload any currently loaded model (text or vision)
        if inferenceEngine.isLoaded {
            inferenceEngine.unloadModel()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await inferenceEngine.loadModel(config)
        loadedModel = config
        return config
    }
    
    /// Load the Fast tier vision model (SmolVLM2)
    func ensureVisionModelLoaded() async throws -> ModelConfig {
        guard let config = RoutingTier.fast.visionModel else {
            throw ModelError.noModelForTier(.fast)
        }
        
        if loadedModel?.id == config.id, inferenceEngine.isLoaded {
            return config
        }
        
        // Unload text model to free memory
        if inferenceEngine.isLoaded {
            inferenceEngine.unloadModel()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        try await inferenceEngine.loadModel(config)
        loadedModel = config
        return config
    }
    
    /// Unload current model to free memory
    func unloadModel() {
        inferenceEngine.unloadModel()
        loadedModel = nil
    }
}

enum ModelError: LocalizedError {
    case noModelForTier(RoutingTier)
    
    var errorDescription: String? {
        switch self {
        case .noModelForTier(let tier):
            return "No model available for \(tier.label) tier"
        }
    }
}
