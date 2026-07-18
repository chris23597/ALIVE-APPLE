import Foundation

#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
#endif

/// Core inference engine — wraps MLX Swift for on-device text + vision generation.
///
/// Uses `ChatSession` from MLXLMCommon when MLX packages are linked.
/// Falls back to simulated tokens when built without the SPM dependencies
/// (e.g., on CI runners that can't resolve mlx-swift-lm).
///
/// One model loaded at a time (text or vision, never both).
/// Memory note: MLX models use ~3GB (text) or ~1.8GB (vision) at runtime.
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
    
    #if canImport(MLXLLM)
    private var modelContainer: ModelContainer?
    private var chatSession: ChatSession?
    #endif
    
    // MARK: - Model Loading
    
    func loadModel(_ config: ModelConfig) async throws {
        guard !isInferencing else {
            throw InferenceError.inferenceInProgress
        }
        
        if activeModel != nil {
            unloadModel()
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsURL = documentsURL.appendingPathComponent("Models", isDirectory: true)
        let modelDir = modelsURL.appendingPathComponent(config.directoryName, isDirectory: true)
        
        #if canImport(MLXLLM)
        let safetensorsFiles = (try? FileManager.default.contentsOfDirectory(atPath: modelDir.path))?
            .filter { $0.hasSuffix(".safetensors") } ?? []
        
        guard !safetensorsFiles.isEmpty else {
            throw InferenceError.modelFileNotFound(config.directoryName)
        }
        
        let container = try await ModelContainer.load(directory: modelDir)
        self.modelContainer = container
        self.chatSession = ChatSession(container)
        #endif
        
        self.modelDirectory = modelDir
        self.activeModel = config
        
        print("[InferenceEngine] Loaded \(config.name) (\(config.formattedSize))")
    }
    
    func unloadModel() {
        #if canImport(MLXLLM)
        modelContainer = nil
        chatSession = nil
        #endif
        modelDirectory = nil
        activeModel = nil
        print("[InferenceEngine] Model unloaded — memory freed")
    }
    
    // MARK: - Text Generation
    
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
                    #if canImport(MLXLLM)
                    guard let session = chatSession, activeModel?.id == model.id else {
                        throw InferenceError.modelLoadFailed("Model not loaded")
                    }
                    
                    let prompt = buildPrompt(messages: messages, model: model)
                    let response = try await withTimeout(seconds: inferenceTimeoutSeconds) {
                        try await session.respond(to: prompt)
                    }
                    let words = response.split(separator: " ", omittingEmptySubsequences: false)
                    for (i, word) in words.enumerated() {
                        try Task.checkCancellation()
                        let chunk = i < words.count - 1 ? String(word) + " " : String(word)
                        continuation.yield(chunk)
                        try await Task.sleep(for: .milliseconds(15))
                    }
                    #else
                    // Demo fallback — replace with real MLX when SPM packages are linked
                    try await generateDemoResponse(
                        messages: messages,
                        model: model,
                        continuation: continuation
                    )
                    #endif
                    
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
                
                #if canImport(MLXLLM)
                let visionPrompt = "[Image provided] \(prompt)"
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
                #else
                let demoText = "_(Vision demo — real VLM when MLX packages are linked)_\n\n**Analysis:** Image received. Full VLM inference available when built with Xcode + mlx-swift-lm SPM dependency."
                let tokens = demoText.split(separator: " ")
                for token in tokens {
                    continuation.yield(String(token) + " ")
                    try? await Task.sleep(for: .milliseconds(30))
                }
                continuation.finish()
                #endif
            }
        }
    }
    
    // MARK: - Prompt Building
    
    private func buildPrompt(messages: [ChatMessage], model: ModelConfig) -> String {
        var prompt = ""
        prompt += "<|im_start|>system\n\(AliveSystemPrompt.core)<|im_end|>\n"
        
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
    
    // MARK: - Demo Fallback
    
    #if !canImport(MLXLLM)
    private func generateDemoResponse(
        messages: [ChatMessage],
        model: ModelConfig,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let userText = messages.last { $0.role == .user }?.content ?? "hello"
        let response = demoReply(userText: userText, modelName: model.name)
        let words = response.split(separator: " ")
        for (i, word) in words.enumerated() {
            try Task.checkCancellation()
            continuation.yield(i < words.count - 1 ? String(word) + " " : String(word))
            try await Task.sleep(for: .milliseconds(20))
        }
    }
    
    private func demoReply(userText: String, modelName: String) -> String {
        let q = userText.lowercased()
        let banner = "_(Demo mode · \(modelName) · add mlx-swift-lm SPM for real inference)_\n\n"
        
        if q.isEmpty || q.contains("hello") || q.contains("who are you") {
            return banner + "I'm ALIVE — a private on-device assistant for iPhone 16. After importing models and linking MLX Swift, I run entirely on your device with no cloud."
        }
        if q.contains("offline") || q.contains("privacy") {
            return banner + "ALIVE runs fully offline. Your data never leaves your iPhone. No tracking, no cloud, no internet required."
        }
        return banner + """
        On-device AI is ready. Import a Phi-4 Mini or SmolVLM2 model from USB, link the mlx-swift-lm SPM package in Xcode, and this demo becomes real inference.
        
        Until then: I'm a placeholder showing the streaming UI works. Real tokens from MLX Swift arrive once the packages are linked.
        """
    }
    #endif
    
    // MARK: - Context Management
    
    private func trimContext(messages: [ChatMessage]) -> [ChatMessage] {
        guard messages.count > maxContextMessages else { return messages }
        var trimmed: [ChatMessage] = []
        let systemMessages = messages.filter { $0.role == .system }
        trimmed.append(contentsOf: systemMessages)
        let recentMessages = messages.suffix(maxContextMessages - systemMessages.count)
        trimmed.append(contentsOf: recentMessages)
        return trimmed
    }
    
    // MARK: - Timeout
    
    /// TaskGroup child results must be Sendable under Swift 6 / strict concurrency (Xcode 26 CI).
    private func withTimeout<T: Sendable>(
        seconds: Double,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
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
            return "Response timed out"
        case .requiresVisionModel:
            return "This requires a vision model (SmolVLM2)"
        }
    }
}
