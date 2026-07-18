import Foundation
import Observation

/// Shared service container — all ViewModels share the same service instances.
/// This matches the architecture doc: "Service Actors (global actors)."
/// Without this, each ViewModel creates its own ModelManager/AutoRouter/etc,
/// causing models loaded in one tab to be invisible to another.
@MainActor
@Observable
final class ServiceContainer {
    let inferenceEngine = InferenceEngine()
    let modelManager: ModelManager
    let autoRouter = AutoRouter()
    let ragService = RAGService()
    let grokService = GrokAPIService()
    let visionService = VisionService()
    let voiceService = VoiceService()
    let keychainManager = KeychainManager()
    let usbImportService = USBImportService()
    
    init() {
        // ModelManager now requires an InferenceEngine to delegate loading to
        modelManager = ModelManager(engine: inferenceEngine)
        
        // Wire embedding provider: RAG uses the loaded model's llama_get_embeddings()
        ragService.embeddingProvider = { [inferenceEngine] text in
            try await inferenceEngine.embedText(text)
        }
        
        // Load previously ingested documents on startup
        Task { try? await ragService.loadChunks() }
    }
    
    /// Shared model-loading state (visible across all views)
    var loadedTextModel: ModelConfig?
    var loadedVisionModel: ModelConfig?
    var currentTier: RoutingTier = .none
    
    /// Ensure the shared ModelManager has the right text model loaded
    func ensureTextModelLoaded(tier: RoutingTier) async throws -> ModelConfig {
        let config = try await modelManager.ensureTextModelLoaded(tier: tier)
        loadedTextModel = config
        currentTier = tier
        return config
    }
    
    /// Ensure the shared ModelManager has the right vision model loaded
    func ensureVisionModelLoaded(tier: RoutingTier) async throws -> ModelConfig {
        let config = try await modelManager.ensureVisionModelLoaded(tier: tier)
        loadedVisionModel = config
        return config
    }
}
