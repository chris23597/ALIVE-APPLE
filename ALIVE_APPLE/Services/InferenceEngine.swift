import Foundation
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

/// Core inference engine — wraps MLX Swift for on-device text + vision generation.
///
/// Uses `ChatSession` from MLXLMCommon for streaming conversation with history.
/// One model loaded at a time (text or vision, never both).
///
/// Memory note: MLX models use ~3GB (text) or ~1.8GB (vision) at runtime.
/// Always check `MemoryMonitor` before loading.
actor InferenceEngine {
    
    // MARK: - Configuration
    
    private let maxTokens = 2048
    private let temperature: Float = 0.7
    private let inferenceTimeoutSeconds: Double = 120
    private let maxContextMessages: Int = 20
    
    // MARK: - State
    
    private var isInferencing: Bool = false
    private var activeModel: ModelConfig?
    private var modelDirectory: URL?
    private var modelContainer: ModelContainer?
    private var chatSession: ChatSession?
    
    // MARK: - Model Loading
    
    func loadModel(_ config: ModelConfig) async throws {
        guard !isInferencing else {
            throw InferenceError.inferenceInProgress
        }
        
        // Unload previous model to free GPU memory
        if activeModel != nil {
            unloadModel()
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsURL = documentsURL.appendingPathComponent("Models", isDirectory: true)
        let modelDir = modelsURL.appendingPathComponent(config.directoryName, isDirectory: true)
        
        // Check if model files exist locally
        let safetensorsFiles = (try? FileManager.default.contentsOfDirectory(atPath: modelDir.path))?
            .filter { $0.hasSuffix(".safetensors") } ?? []
        
        guard !safetensorsFiles.isEmpty else {
            throw InferenceError.modelFileNotFound(config.directoryName)
        }
        
        print("[InferenceEngine] Loading \(config.name) from \(modelDir.path)")
        
        do {
            // Load model container from local safetensors
            let container = try await ModelContainer.load(directory: modelDir)
            self.modelContainer = container
            self.chatSession = ChatSession(container)
            self.modelDirectory = modelDir
            self.activeModel = config
            
            print("[InferenceEngine] Loaded \(config.name) (\(config.formattedSize)) — ready")
        } catch {
            throw InferenceError.modelLoadFailed(error.localizedDescription)
        }
    }
    
    func unloadModel() {
        modelContainer = nil
        chatSession = nil
        modelDirectory = nil
        activeModel = nil
        print("[InferenceEngine] Model unloaded — GPU memory freed")
    }
    
    // MARK: - Text Generation
    
    /// Generate a streaming response using MLX ChatSession.
    /// Returns `AsyncThrowingStream<String, Error>` for SwiftUI integration.
    func generate(
        messages: [ChatMessage],
        model: ModelConfig,
        temperature: Float = 0.7,
        maxTokens: Int = 2048
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard !isInferencing else {
                    continuation.finish(throwing: InferenceError.inferenceInProgress)
                    return
                }
                
                isInferencing = true
                defer { isInferencing = false }
                
                do {
                    guard let session = chatSession, activeModel?.id == model.id else {
                        throw InferenceError.modelLoadFailed("Model not loaded. Call loadModel() first.")
                    }
                    
                    // Build prompt from messages
                    let prompt = buildPrompt(messages: messages, model: model)
                    
                    // Generate with streaming via ChatSession
                    let response = try await withTimeout(seconds: inferenceTimeoutSeconds) {
                        try await session.respond(to: prompt)
                    }
                    
                    // ChatSession.respond() returns the full response.
                    // For streaming, we split into word-level chunks to simulate token streaming.
                    // MLX Swift's lower-level generate() API can provide true token streaming
                    // when needed — ChatSession is the recommended high-level API for v1.
                    let words = response.split(separator: " ", omittingEmptySubsequences: false)
                    for (i, word) in words.enumerated() {
                        try Task.checkCancellation()
                        let chunk = i < words.count - 1 ? String(word) + " " : String(word)
                        continuation.yield(chunk)
                        // Small delay for natural streaming feel
                        try await Task.sleep(for: .milliseconds(15))
                    }
                    
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: InferenceError.timeout)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Vision Generation
    
    /// Generate a vision-language response for an image.
    /// Currently returns a placeholder — full VLM integration deferred to Phase 2.
    func generateVision(
        image: Data,
        prompt: String,
        model: ModelConfig
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard model.modelType == .vision else {
                    continuation.finish(throwing: InferenceError.requiresVisionModel)
                    return
                }
                
                // Vision with MLX Swift VLMs uses the same ChatSession,
                // passing the image as part of the prompt context.
                // Full integration in Phase 2.
                let visionPrompt = "[Image provided] \(prompt)"
                
                // Fall back to text generation for now
                let messages = [ChatMessage(role: .user, content: visionPrompt)]
                let stream = generate(messages: messages, model: model)
                
                do {
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
    
    // MARK: - Prompt Building
    
    private func buildPrompt(messages: [ChatMessage], model: ModelConfig) -> String {
        var prompt = ""
        
        // System prompt first
        prompt += "<|im_start|>system\n\(AliveSystemPrompt.core)<|im_end|>\n"
        
        // History + current message
        let trimmed = trimContext(messages: messages)
        for message in trimmed {
            switch message.role {
            case .system:
                prompt += "<|im_start|>system\n\(message.content)<|im_end|>\n"
            case .user:
                prompt += "<|im_start|>user\n\(message.content)<|im_end|>\n"
            case .assistant:
                prompt += "<|im_start|>assistant\n\(message.content)<|im_end|>\n"
            }
        }
        
        prompt += "<|im_start|>assistant\n"
        return prompt
    }
    
    // MARK: - Context Management
    
    private func trimContext(messages: [ChatMessage]) -> [ChatMessage] {
        guard messages.count > maxContextMessages else { return messages }
        
        var trimmed: [ChatMessage] = []
        let systemMessages = messages.filter { $0.role == .system }
        trimmed.append(contentsOf: systemMessages)
        let recentMessages = messages.suffix(maxContextMessages - systemMessages.count)
        trimmed.append(contentsOf: recentMessages)
        
        print("[InferenceEngine] Trimmed: \(messages.count) → \(trimmed.count) messages")
        return trimmed
    }
    
    // MARK: - Timeout
    
    private func withTimeout<T>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw InferenceError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - State Queries
    
    var isLoaded: Bool {
        activeModel != nil && modelDirectory != nil
    }
    
    var activeModelId: String? {
        activeModel?.id
    }
    
    var loadedModelDisplayName: String? {
        activeModel?.name
    }
    
    var contextSize: Int {
        activeModel?.contextSize ?? 0
    }
}

// MARK: - Errors

enum InferenceError: LocalizedError {
    case modelFileNotFound(String)
    case modelLoadFailed(String)
    case inferenceInProgress
    case timeout
    case requiresVisionModel
    
    var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let name):
            return "Model not found: \(name). Import from USB first."
        case .modelLoadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .inferenceInProgress:
            return "Another response is already generating"
        case .timeout:
            return "Response timed out (partial result shown)"
        case .requiresVisionModel:
            return "This requires a vision model (SmolVLM2)"
        }
    }
}
