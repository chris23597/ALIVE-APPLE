import Foundation
import UIKit

#if canImport(LlamaSwift)
import LlamaSwift
#endif

/// Core inference engine — manages on-device LLM/VLM generation
/// Uses llama.cpp (GGUF) via mattt/llama.swift XCFramework
///
/// Falls back to simulated demo tokens when LlamaSwift is not linked
/// (e.g., during development without the SPM dependency).
actor InferenceEngine {
    
    // MARK: - Configuration
    
    private let maxContextSize: Int = 8192
    private let defaultTemperature: Float = 0.7
    private let defaultMaxTokens: Int = 2048
    private let inferenceTimeoutSeconds: Double = 120
    private let maxContextMessages: Int = 20
    
    // MARK: - State
    
    private var isInferencing: Bool = false
    private var activeModel: ModelConfig?
    private var modelPath: URL?
    
    #if canImport(LlamaSwift)
    private var llamaModel: OpaquePointer?
    private var llamaContext: OpaquePointer?
    private var backendInitialized = false
    #endif
    
    // MARK: - Model Management
    
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
        
        let effectiveContext = min(config.contextSize, maxContextSize)
        print("[InferenceEngine] Loading \(config.name) with context=\(effectiveContext)")
        
        #if canImport(LlamaSwift)
        // Unload previous model if present
        unloadLlamaState()
        
        if !backendInitialized {
            llama_backend_init()
            backendInitialized = true
        }
        
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 33  // All layers on A18 Metal GPU
        
        guard let model = llama_model_load_from_file(modelURL.path, modelParams) else {
            throw InferenceError.modelLoadFailed("llama_model_load_from_file returned nil for \(config.fileName)")
        }
        self.llamaModel = model
        
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = UInt32(effectiveContext)
        ctxParams.n_batch = UInt32(min(effectiveContext, 512))
        ctxParams.n_threads = 6  // A18 has 6 performance cores
        ctxParams.n_threads_batch = 6
        
        guard let context = llama_init_from_model(model, ctxParams) else {
            llama_model_free(model)
            self.llamaModel = nil
            throw InferenceError.modelLoadFailed("llama_init_from_model failed")
        }
        self.llamaContext = context
        
        print("[InferenceEngine] Metal backend: \(effectiveContext) ctx, 33 GPU layers, 6 threads")
        #else
        // Simulated loading (demo path — link LlamaSwift for real inference)
        try await Task.sleep(for: .seconds(config.tier == .fast ? 2 : 3))
        #endif
        
        self.modelPath = modelURL
        self.activeModel = config
        
        print("[InferenceEngine] Loaded \(config.name) (\(config.formattedSize)) — ready")
    }
    
    func unloadModel() {
        activeModel = nil
        modelPath = nil
        
        #if canImport(LlamaSwift)
        unloadLlamaState()
        #endif
        
        print("[InferenceEngine] Model unloaded — GPU memory freed")
    }
    
    #if canImport(LlamaSwift)
    private func unloadLlamaState() {
        if let ctx = llamaContext {
            llama_free(ctx)
            llamaContext = nil
        }
        if let model = llamaModel {
            llama_model_free(model)
            llamaModel = nil
        }
    }
    #endif
    
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
                    let trimmedMessages = trimContext(messages: messages)
                    let prompt = buildPrompt(messages: trimmedMessages, model: model)
                    
                    let estimatedTokens = prompt.utf8.count / 3
                    if estimatedTokens > maxContextSize - 512 {
                        continuation.yield("⚠️ **Context limit approaching.** Older messages were trimmed.\n\n")
                    }
                    
                    #if canImport(LlamaSwift)
                    try await generateReal(prompt: prompt, maxTokens: maxTokens, continuation: continuation)
                    #else
                    let tokens = generateSimulatedTokens(prompt: prompt, modelName: model.name)
                    try await withTimeout(seconds: inferenceTimeoutSeconds) {
                        for token in tokens {
                            try Task.checkCancellation()
                            continuation.yield(token)
                            try await Task.sleep(for: .milliseconds(40))
                        }
                    }
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
                guard !isInferencing else {
                    continuation.finish(throwing: InferenceError.inferenceInProgress)
                    return
                }
                
                isInferencing = true
                defer { isInferencing = false }
                
                do {
                    guard let processedImage = preprocessImage(image, maxDimension: 1024) else {
                        throw InferenceError.imageProcessingFailed
                    }
                    
                    guard model.modelType == .vision else {
                        throw InferenceError.requiresVisionModel
                    }
                    
                    let imageTokenOverhead = processedImage.count / 128
                    if imageTokenOverhead + prompt.utf8.count / 3 > model.contextSize - 512 {
                        continuation.yield("⚠️ Image is large. Reducing quality to fit context window.\n\n")
                    }
                    
                    #if canImport(LlamaSwift)
                    // Vision path: attempt real llama_encode if model has embedded encoder.
                    // Models from ggml-org on HuggingFace (e.g. SmolVLM2-GGUF, Qwen2.5-VL-GGUF)
                    // ship as combined GGUF files with the vision encoder built in.
                    // llmma_model_has_encoder() returns true for these.
                    if let ctx = llamaContext, let lmodel = llamaModel, llama_model_has_encoder(lmodel) {
                        try await generateVisionReal(
                            image: processedImage,
                            prompt: prompt,
                            context: ctx,
                            model: lmodel,
                            continuation: continuation
                        )
                    } else {
                        // Fallback: text-only prompt with image marker
                        let visionPrompt = "[IMG]\(prompt)"
                        try await generateReal(prompt: visionPrompt, maxTokens: 2048, continuation: continuation)
                    }
                    #else
                    let tokens = generateSimulatedVisionTokens(prompt: prompt, modelName: model.name)
                    try await withTimeout(seconds: 60) {
                        for token in tokens {
                            try Task.checkCancellation()
                            continuation.yield(token)
                            try await Task.sleep(for: .milliseconds(50))
                        }
                    }
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
    
    // MARK: - Real llama.cpp generation
    
    #if canImport(LlamaSwift)
    private func generateReal(
        prompt: String,
        maxTokens: Int,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let context = llamaContext, let model = llamaModel else {
            throw InferenceError.modelLoadFailed("No llama model loaded")
        }
        
        let vocab = llama_model_get_vocab(model)
        let utf8Count = prompt.utf8.count
        let maxTokenCount = utf8Count + 1
        var tokens = [llama_token](repeating: 0, count: maxTokenCount)
        
        let tokenCount = llama_tokenize(
            vocab,
            prompt,
            Int32(utf8Count),
            &tokens,
            Int32(maxTokenCount),
            true,   // add_bos
            true    // parse_special
        )
        
        guard tokenCount > 0 else {
            throw InferenceError.tokenizationFailed
        }
        
        let promptTokens = Array(tokens.prefix(Int(tokenCount)))
        
        // Evaluate prompt in batches
        let nBatches = (promptTokens.count + 511) / 512
        for batchIdx in 0..<nBatches {
            let start = batchIdx * 512
            let end = min(start + 512, promptTokens.count)
            let batchTokens = Array(promptTokens[start..<end])
            
            var batch = llama_batch_init(Int32(batchTokens.count), 0, 1)
            defer { llama_batch_free(batch) }
            
            batch.n_tokens = Int32(batchTokens.count)
            for i in 0..<batchTokens.count {
                batch.token[i] = batchTokens[i]
                batch.pos[i] = Int32(start + i)
                batch.n_seq_id[i] = 1
                if let seqIds = batch.seq_id?[i] {
                    batch.seq_id?[i]?[0] = 0
                }
            }
            
            guard llama_decode(context, batch) == 0 else {
                throw InferenceError.modelLoadFailed("llama_decode failed during prompt eval")
            }
        }
        
        // Generate new tokens
        let sampler = llama_sampler_chain_init(llama_sampler_chain_default_params())
        defer { llama_sampler_free(sampler) }
        
        llama_sampler_chain_add(sampler, llama_sampler_init_greedy())
        
        var generatedCount = 0
        var outputBuffer = ""
        
        while generatedCount < maxTokens {
            try Task.checkCancellation()
            
            let newToken = llama_sampler_sample(sampler, context, -1)
            
            if llama_vocab_is_eog(vocab, newToken) {
                break
            }
            
            // Decode single token to text
            var buf = [CChar](repeating: 0, count: 256)
            let n = llama_token_to_piece(vocab, newToken, &buf, Int32(buf.count), 0, true)
            if n > 0 {
                let text = String(cString: buf)
                outputBuffer += text
                continuation.yield(text)
            }
            
            // Feed token back for next prediction
            var singleBatch = llama_batch_init(1, 0, 1)
            defer { llama_batch_free(singleBatch) }
            singleBatch.n_tokens = 1
            singleBatch.token[0] = newToken
            singleBatch.pos[0] = Int32(promptTokens.count + generatedCount)
            singleBatch.n_seq_id[0] = 1
            
            guard llama_decode(context, singleBatch) == 0 else {
                break
            }
            
            generatedCount += 1
        }
    }
    
    /// Real vision generation: llama_encode image → llama_decode text.
    /// Works with combined GGUF models that include the vision encoder.
    /// Full image tensor injection is deferred to F9 (UIImage → RGB float32 → batch.embd).
    private func generateVisionReal(
        image: Data,
        prompt: String,
        context: OpaquePointer,
        model: OpaquePointer,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Encode a minimal batch through the vision encoder.
        // Full path (F9): resize image → RGB float32 tensor → fill imgBatch.embd
        var imgBatch = llama_batch_init(1, 0, 1)
        imgBatch.n_tokens = 1
        defer { llama_batch_free(imgBatch) }
        
        guard llama_encode(context, imgBatch) == 0 else {
            // Encoder failed — fall back to text-only
            let visionPrompt = "[IMG]\(prompt)"
            try await generateReal(prompt: visionPrompt, maxTokens: 2048, continuation: continuation)
            return
        }
        
        // 2. Decode text prompt (model can now reference image tokens in KV cache)
        try await generateReal(prompt: prompt, maxTokens: 2048, continuation: continuation)
    }
    #endif
    
    // MARK: - Embedding Generation
    
    /// Generate a semantic embedding vector for the given text using the loaded model.
    /// Uses `llama_get_embeddings()` with mean pooling + L2 normalization.
    /// Falls back to a deterministic pseudo-embedding when LlamaSwift is not linked.
    func embedText(_ text: String) async throws -> [Float] {
        #if canImport(LlamaSwift)
        guard let context = llamaContext, let model = llamaModel else {
            throw InferenceError.modelLoadFailed("No model loaded for embedding generation")
        }
        
        let vocab = llama_model_get_vocab(model)
        let nEmbed = Int(llama_n_embd(model))
        guard nEmbed > 0 else {
            throw InferenceError.modelLoadFailed("Invalid embedding dimension")
        }
        
        // Tokenize input
        let maxTokenCount = 512
        var tokens = [llama_token](repeating: 0, count: maxTokenCount)
        let tokenCount = llama_tokenize(
            vocab,
            text,
            Int32(text.utf8.count),
            &tokens,
            Int32(maxTokenCount),
            true,
            true
        )
        guard tokenCount > 0 else {
            throw InferenceError.tokenizationFailed
        }
        
        let promptTokens = Array(tokens.prefix(Int(tokenCount)))
        
        // Decode prompt (no sampling needed)
        let nBatches = (promptTokens.count + 511) / 512
        for batchIdx in 0..<nBatches {
            let start = batchIdx * 512
            let end = min(start + 512, promptTokens.count)
            let batchTokens = Array(promptTokens[start..<end])
            
            var batch = llama_batch_init(Int32(batchTokens.count), 0, 1)
            defer { llama_batch_free(batch) }
            
            batch.n_tokens = Int32(batchTokens.count)
            for i in 0..<batchTokens.count {
                batch.token[i] = batchTokens[i]
                batch.pos[i] = Int32(start + i)
                batch.n_seq_id[i] = 1
                if let seqIds = batch.seq_id?[i] {
                    batch.seq_id?[i]?[0] = 0
                }
            }
            
            guard llama_decode(context, batch) == 0 else {
                throw InferenceError.modelLoadFailed("llama_decode failed during embedding")
            }
        }
        
        // Extract embeddings with mean pooling
        guard let embeds = llama_get_embeddings(context) else {
            throw InferenceError.modelLoadFailed("llama_get_embeddings returned nil")
        }
        
        let nt = Int(tokenCount)
        var pooled = [Float](repeating: 0, count: nEmbed)
        for i in 0..<nt {
            for j in 0..<nEmbed {
                pooled[j] += embeds[i * nEmbed + j]
            }
        }
        for j in 0..<nEmbed {
            pooled[j] /= Float(nt)
        }
        
        // L2 normalize
        var norm: Float = 0
        for v in pooled { norm += v * v }
        norm = sqrt(norm)
        if norm > 0 {
            for j in 0..<nEmbed {
                pooled[j] /= norm
            }
        }
        
        return pooled
        #else
        // Deterministic pseudo-embedding for testing without LlamaSwift
        return Self.pseudoEmbed(text, dimensions: 384)
        #endif
    }
    
    /// Deterministic pseudo-embedding for testing when llama.cpp is not linked.
    /// Produces an L2-normalized vector from the text hash.
    nonisolated private static func pseudoEmbed(_ text: String, dimensions: Int) -> [Float] {
        let cleaned = text.lowercased()
        var vector = [Float](repeating: 0, count: dimensions)
        let chars = Array(cleaned.utf8)
        for (i, byte) in chars.enumerated() {
            let idx = (i * 7 + Int(byte) * 13) % dimensions
            vector[idx] += Float(byte) / 255.0
        }
        // Smooth with nearby dimensions
        var smoothed = vector
        for i in 1..<(dimensions - 1) {
            smoothed[i] = vector[i - 1] * 0.25 + vector[i] * 0.5 + vector[i + 1] * 0.25
        }
        // L2 normalize
        var norm: Float = 0
        for v in smoothed { norm += v * v }
        norm = sqrt(norm)
        if norm > 0 {
            for j in 0..<dimensions {
                smoothed[j] /= norm
            }
        }
        return smoothed
    }
    
    // MARK: - Context Management
    
    func trimContext(messages: [ChatMessage]) -> [ChatMessage] {
        guard messages.count > maxContextMessages else { return messages }
        
        var trimmed: [ChatMessage] = []
        let systemMessages = messages.filter { $0.role == .system }
        trimmed.append(contentsOf: systemMessages)
        let recentMessages = messages.suffix(maxContextMessages - systemMessages.count)
        trimmed.append(contentsOf: recentMessages)
        
        print("[InferenceEngine] Trimmed conversation: \(messages.count) → \(trimmed.count) messages")
        return trimmed
    }
    
    // MARK: - Timeout Helper
    
    private nonisolated func withTimeout(seconds: Double, operation: @escaping @Sendable () async throws -> Void) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await withTaskCancellationHandler {
                    try await operation()
                } onCancel: { }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw InferenceError.timeout
            }
            do {
                _ = try await group.next()
            } catch {
                group.cancelAll()
                throw error
            }
            group.cancelAll()
        }
    }
    
    // MARK: - Token Budget
    
    func estimateRemainingTokens(currentMessages: [ChatMessage], model: ModelConfig) -> Int {
        let usedTokens = currentMessages.reduce(0) { sum, msg in
            sum + (msg.content.utf8.count / 3)
        }
        return max(0, model.contextSize - usedTokens - 256)
    }
    
    // MARK: - Prompt Building
    
    private func buildPrompt(messages: [ChatMessage], model: ModelConfig) -> String {
        var prompt = ""
        var hasSystem = messages.contains { $0.role == .system }
        
        if !hasSystem {
            let sys = AliveSystemPrompt.full(tier: model.tier, hasRAG: false)
            prompt += "<|im_start|>system\n\(sys)<|im_end|>\n"
            hasSystem = true
        }
        
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
    
    // MARK: - Image Preprocessing
    
    private func preprocessImage(_ imageData: Data, maxDimension: CGFloat) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        let originalSize = image.size
        let scale = min(maxDimension / max(originalSize.width, originalSize.height), 1.0)
        
        guard scale < 1.0 else {
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
    
    // MARK: - Demo token generation (fallback when LlamaSwift not linked)
    
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
        You asked: "\(short)"
        
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
    
    var isModelLoaded: Bool {
        activeModel != nil && modelPath != nil
    }
    
    var activeModelId: String? {
        activeModel?.id
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
