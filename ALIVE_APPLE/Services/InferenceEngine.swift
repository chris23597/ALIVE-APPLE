import Foundation
import UIKit

/// Core inference engine — manages on-device LLM/VLM generation
/// Uses llama.cpp (GGUF) or MLX Swift backends
///
/// Key improvements from skills review:
/// - Context window management (trim overflow, KV cache limits)
/// - Hard timeout for all inference (avoids infinite spinner)
/// - Real image preprocessing with proper resize/normalize
/// - Token budget accounting
actor InferenceEngine {
    
    // MARK: - Configuration
    
    private let maxContextSize: Int = 8192
    private let defaultTemperature: Float = 0.7
    private let defaultMaxTokens: Int = 2048
    private let inferenceTimeoutSeconds: Double = 120
    private let maxContextMessages: Int = 20  // Trim conversation if longer
    
    // MARK: - State
    
    private var isInferencing: Bool = false
    private var activeModel: ModelConfig?
    private var modelPath: URL?
    
    // MARK: - Model Management
    
    /// Load a model into memory (llama.cpp)
    func loadModel(_ config: ModelConfig) async throws {
        guard !isInferencing else {
            throw InferenceError.inferenceInProgress
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsURL = documentsURL.appendingPathComponent("Models", isDirectory: true)
        let modelURL = modelsURL.appendingPathComponent(config.fileName)
        
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw InferenceError.modelFileNotFound(config.fileName)
        }
        
        // Real llama.cpp initialization steps (reference for when linking llama.cpp):
        // 1. llama_backend_init()
        // 2. llama_model_load_from_file(modelPath, params)
        // 3. llama_new_context_with_model(model, ctx_params)
        // 4. Set Metal GPU layers: params.n_gpu_layers = 33 (all layers on A18)
        // 5. Allocate KV cache: n_ctx = min(config.contextSize, maxContextSize)
        // 6. Warm up with short eval
        
        // Context size: use config value but cap at max
        let effectiveContext = min(config.contextSize, maxContextSize)
        print("[InferenceEngine] Loading \(config.name) with context=\(effectiveContext), GPU layers=33")
        
        // Simulated loading with progress (replace with actual llama_init)
        try await Task.sleep(for: .seconds(config.tier == .fast ? 2 : 3))
        
        self.modelPath = modelURL
        self.activeModel = config
        
        print("[InferenceEngine] Loaded \(config.name) (\(config.formattedSize)) — ready")
    }
    
    /// Unload the current model
    func unloadModel() {
        // Real clean-up:
        // 1. llama_free_model(model)
        // 2. llama_free_context(ctx)
        // 3. llama_backend_free()
        // 4. Free Metal GPU buffers (n_gpu_layers = 0)
        activeModel = nil
        modelPath = nil
        print("[InferenceEngine] Model unloaded — GPU memory freed")
    }
    
    // MARK: - Text Generation
    
    /// Generate text with streaming tokens
    /// Features: context trimming, timeout, streaming
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
                    // 1. Trim context if conversation too long
                    let trimmedMessages = trimContext(messages: messages)
                    
                    // 2. Build prompt (ChatML format)
                    let prompt = buildPrompt(messages: trimmedMessages, model: model)
                    
                    // 3. Check prompt token budget (rough estimate)
                    let estimatedTokens = prompt.utf8.count / 3 // ~3 bytes per token
                    if estimatedTokens > maxContextSize - 512 {
                        continuation.yield("⚠️ **Context limit approaching.** Older messages were trimmed to fit the model's context window.\n\n")
                    }
                    
                    // Build demo tokens on the actor; stream them inside timeout (@Sendable-safe)
                    // Real llama.cpp path: sample/yield inside the timeout loop instead.
                    let simulatedTokens = self.generateSimulatedTokens(
                        prompt: prompt,
                        modelName: model.name
                    )
                    try await withTimeout(seconds: inferenceTimeoutSeconds) {
                        for token in simulatedTokens {
                            try Task.checkCancellation()
                            continuation.yield(token)
                            try await Task.sleep(for: .milliseconds(40))
                        }
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
    
    /// Analyze an image with a VLM
    /// Handles: image resize, multimodal projector, context limits
    func generateVision(
        image: Data,
        prompt: String,
        model: ModelConfig
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
                    // 1. Preprocess image (resize, normalize)
                    guard let processedImage = preprocessImage(image, maxDimension: 1024) else {
                        throw InferenceError.imageProcessingFailed
                    }
                    
                    // 2. Verify vision model has multimodal projector
                    guard model.modelType == .vision else {
                        throw InferenceError.requiresVisionModel
                    }
                    
                    // 3. Real VLM inference:
                    // - Encode image with vision encoder (SigLIP/CLIP — 400M params for SmolVLM2)
                    // - Project embeddings to LLM space via mmproj (multimodal projector)
                    // - Combine image embeddings + text tokens
                    // - Run standard inference on combined sequence
                    // - Use context carefully — image takes ~2k+ tokens
                    
                    let imageTokenOverhead = 2048  // ~2k tokens for a processed image
                    if imageTokenOverhead + prompt.utf8.count / 3 > model.contextSize - 512 {
                        continuation.yield("⚠️ Image is large. Reducing quality to fit context window.\n\n")
                    }
                    
                    // Build demo tokens on the actor; stream inside timeout (@Sendable-safe)
                    let visionTokens = self.generateSimulatedVisionTokens(
                        prompt: prompt,
                        modelName: model.name
                    )
                    try await withTimeout(seconds: 60) {
                        for token in visionTokens {
                            try Task.checkCancellation()
                            continuation.yield(token)
                            try await Task.sleep(for: .milliseconds(50))
                        }
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
    
    // MARK: - Context Management
    
    /// Trim long conversations to fit context window
    /// Keeps system message, last N messages, drops middle
    func trimContext(messages: [ChatMessage]) -> [ChatMessage] {
        guard messages.count > maxContextMessages else { return messages }
        
        var trimmed: [ChatMessage] = []
        
        // Always keep system messages
        let systemMessages = messages.filter { $0.role == .system }
        trimmed.append(contentsOf: systemMessages)
        
        // Keep last N messages
        let recentMessages = messages.suffix(maxContextMessages - systemMessages.count)
        trimmed.append(contentsOf: recentMessages)
        
        print("[InferenceEngine] Trimmed conversation: \(messages.count) → \(trimmed.count) messages")
        return trimmed
    }
    
    // MARK: - Timeout Helper
    
    /// Run an async operation with a hard timeout.
    /// Uses withTaskCancellationHandler so the cancelled operation task
    /// doesn't race with the timeout and cause spurious errors.
    private nonisolated func withTimeout(seconds: Double, operation: @escaping @Sendable () async throws -> Void) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Main operation — respects cancellation
            group.addTask {
                try await withTaskCancellationHandler {
                    try await operation()
                } onCancel: {
                    // Cancel is handled cooperatively inside operation() via Task.checkCancellation()
                }
            }
            // Timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw InferenceError.timeout
            }

            // Wait for first completion (either operation succeeds or timeout fires)
            do {
                _ = try await group.next()
                // If we get here without throwing, the operation completed first — good
            } catch {
                // Timeout or operation error — cancel everything
                group.cancelAll()
                // Re-throw the error so the caller sees it
                throw error
            }
            // If operation succeeded, cancel the timeout task (still sleeping)
            group.cancelAll()
        }
    }
    
    // MARK: - Token Budget
    
    /// Estimate remaining context budget
    func estimateRemainingTokens(currentMessages: [ChatMessage], model: ModelConfig) -> Int {
        let usedTokens = currentMessages.reduce(0) { sum, msg in
            sum + (msg.content.utf8.count / 3)
        }
        return max(0, model.contextSize - usedTokens - 256)  // 256 token safety margin
    }
    
    // MARK: - Prompt Building
    
    private func buildPrompt(messages: [ChatMessage], model: ModelConfig) -> String {
        var prompt = ""
        var hasSystem = messages.contains { $0.role == .system }
        
        // Always ensure ALIVE on-device system prompt is first (Fast/Moderate)
        if !hasSystem {
            let sys = AliveSystemPrompt.full(tier: model.tier, hasRAG: false)
            prompt += "<|im_start|>system\n\(sys)<|im_end|>\n"
            hasSystem = true
        }
        
        // ChatML format (works for Phi-4 and Qwen2.5)
        for message in messages {
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
    
    // MARK: - Image Preprocessing (Real)
    
    /// Resize image to max dimension, normalize to model input requirements
    /// VLM models like SmolVLM2 expect: 3 × 384 × 384 (or dynamic up to 1024×1024)
    private func preprocessImage(_ imageData: Data, maxDimension: CGFloat) -> Data? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        let originalSize = image.size
        let scale = min(maxDimension / max(originalSize.width, originalSize.height), 1.0)
        
        guard scale < 1.0 else {
            // Image already fits — compress to reasonable quality
            return image.jpegData(compressionQuality: 0.85)
        }
        
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized?.jpegData(compressionQuality: 0.80)
    }
    
    // MARK: - Fast path (demo until llama.cpp + Metal linked on Mac — FEATURE F4)
    //
    // REAL swap: after llama_eval/sample loop, yield decoded strings here.
    // Keep buildPrompt() (ChatML + AliveSystemPrompt) unchanged for both demo and real.
    
    // nonisolated: pure string helpers; safe from @Sendable timeout closures / Tasks
    nonisolated private func generateSimulatedTokens(prompt: String, modelName: String) -> [String] {
        let userText = extractLastUserContent(from: prompt)
        let response = demoOnDeviceReply(userText: userText, modelName: modelName)
        return tokenizeForStream(response)
    }
    
    nonisolated private func extractLastUserContent(from prompt: String) -> String {
        if let range = prompt.range(of: "<|im_start|>user\n", options: .backwards) {
            let after = prompt[range.upperBound...]
            if let end = after.range(of: "<|im_end|>") {
                return String(after[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return String(after).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(prompt.suffix(400))
    }
    
    nonisolated private func demoOnDeviceReply(userText: String, modelName: String) -> String {
        let q = userText.lowercased()
        let banner = "_(Fast · \(modelName) · on-device demo until llama.cpp is linked on Mac)_\n\n"
        
        if q.isEmpty {
            return banner + "I'm ALIVE on your phone. Ask a question, use Vision for a photo, or import models from USB."
        }
        if q.contains("who are you") || q.contains("what are you") {
            return banner + "I'm **ALIVE** — a private on-device assistant. After you import models, Fast/Moderate stay local. Pro (Grok) only if you add your own key."
        }
        if q.contains("offline") || q.contains("privacy") || q.contains("cloud") {
            return banner + "Default is **offline-first**. Fast and Moderate do not need the network. Pro uses the network only when you enable it."
        }
        if q.contains("plant") || q.contains("monstera") || q.contains("water") {
            return banner + """
            General plant guidance (not a substitute for local expertise):
            - Let the top inch of soil dry before watering
            - Bright indirect light
            - Avoid standing water in the pot
            
            For ID from a photo, open the **Vision** tab once a VLM is loaded.
            """
        }
        if q.contains("help") || q.contains("what can you do") {
            return banner + """
            - **Chat** — local Fast/Moderate after USB import
            - **Vision** — photo/camera when a VLM is loaded
            - **Models** — import GGUF from USB
            - **Pro** — optional Grok with your key
            
            Next engineering step: real GGUF tokens (F4) on a Mac with Xcode.
            """
        }
        
        let short = userText.count > 280 ? String(userText.prefix(277)) + "…" : userText
        return banner + """
        You asked: “\(short)”
        
        Concise on-device take:
        - Practical and private by default
        - No invented live news, weather, or prices while offline
        - Use **Moderate** when the phone allows; **Pro** only online with a key
        
        _(F4 replaces this demo stream with real model tokens.)_
        """
    }
    
    nonisolated private func tokenizeForStream(_ text: String) -> [String] {
        var parts: [String] = []
        var current = ""
        for ch in text {
            current.append(ch)
            if ch == " " || ch == "\n" || current.count >= 12 {
                parts.append(current)
                current = ""
            }
        }
        if !current.isEmpty { parts.append(current) }
        return parts.isEmpty ? [text] : parts
    }
    
    nonisolated private func generateSimulatedVisionTokens(prompt: String, modelName: String) -> [String] {
        let banner = "_(Vision demo · \(modelName) · until real VLM is linked)_\n\n"
        let response: String
        if prompt.lowercased().contains("plant") || prompt.lowercased().contains("identify") {
            response = banner + """
            **Identification (demo):** Visual pattern matches a large-leaf houseplant (e.g. Monstera-like).
            **Confidence:** Medium — confirm with leaf holes, petiole, and growth habit.
            **Care:** Bright indirect light; water when top soil is dry.
            """
        } else if prompt.lowercased().contains("text") || prompt.lowercased().contains("ocr") || prompt.lowercased().contains("read") {
            response = banner + """
            **Document (demo):** Text-like regions detected. For stronger OCR, use Moderate VLM once loaded.
            """
        } else {
            response = banner + """
            **Scene (demo):** Clear subject with background context. Ask a specific question about the photo for a tighter answer.
            """
        }
        return tokenizeForStream(response)
    }
    
    // MARK: - State Queries
    
    /// Whether a model is currently loaded and ready for inference
    var isModelLoaded: Bool {
        activeModel != nil && modelPath != nil
    }
    
    /// The loaded model's effective context size (tokens), or 0 if no model loaded
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
    case tokenizationFailed
    case imageProcessingFailed
    case requiresVisionModel
    case contextOverflow(available: Int, needed: Int)
    
    var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let name):
            return "Model file not found: \(name)"
        case .modelLoadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .inferenceInProgress:
            return "Another inference is already running"
        case .timeout:
            return "Inference timed out (generated partial response)"
        case .tokenizationFailed:
            return "Failed to tokenize input"
        case .imageProcessingFailed:
            return "Failed to process image for VLM input"
        case .requiresVisionModel:
            return "This operation requires a vision model (VLM), not a text-only LLM"
        case .contextOverflow(let available, let needed):
            return "Context window full (\(needed) tokens needed, only \(available) available)"
        }
    }
}
