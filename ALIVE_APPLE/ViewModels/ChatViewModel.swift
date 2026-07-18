import Foundation
import Observation

/// ViewModel for the chat interface — v1 simplified.
/// Single Fast tier, no auto-routing, direct MLX inference.
@MainActor
@Observable
final class ChatViewModel {
    
    // MARK: - Published State
    
    var messages: [ChatMessage] = []
    var currentStreamingMessage: String = ""
    var isGenerating: Bool = false
    var currentTier: RoutingTier = .fast
    var errorMessage: String?
    
    // MARK: - Services (injected by view)
    
    var services: ServiceContainer?
    var appState: AppState?
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String, image: Data? = nil) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let services else {
            errorMessage = "Services not initialized"
            return
        }
        
        let userMessage = ChatMessage(
            role: .user,
            content: text,
            hasImage: image != nil,
            imageData: image
        )
        messages.append(userMessage)
        
        isGenerating = true
        currentStreamingMessage = ""
        errorMessage = nil
        currentTier = .fast
        
        do {
            // 1. Load text model (or vision model if image present)
            let model: ModelConfig
            if image != nil {
                model = try await services.ensureVisionModelLoaded()
            } else {
                model = try await services.ensureTextModelLoaded()
            }
            
            // 2. Build message list with system prompt
            var inferenceMessages = messages
            let sys = ChatMessage(
                role: .system,
                content: AliveSystemPrompt.core
            )
            inferenceMessages.removeAll { $0.role == .system }
            inferenceMessages.insert(sys, at: 0)
            
            // 3. Run inference
            let stream: AsyncThrowingStream<String, Error>
            if let imageData = image {
                stream = await services.inferenceEngine.generateVision(
                    image: imageData,
                    prompt: text,
                    model: model
                )
            } else {
                stream = await services.inferenceEngine.generate(
                    messages: inferenceMessages,
                    model: model
                )
            }
            
            // 4. Collect streaming response
            var fullResponse = ""
            for try await token in stream {
                fullResponse += token
                currentStreamingMessage = fullResponse
            }
            
            // 5. Save assistant message
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: fullResponse,
                tierUsed: currentTier.rawValue
            )
            messages.append(assistantMessage)
            
        } catch {
            errorMessage = error.localizedDescription
            
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "Sorry, I encountered an error: \(error.localizedDescription)",
                tierUsed: currentTier.rawValue
            )
            messages.append(errorMsg)
        }
        
        isGenerating = false
        currentStreamingMessage = ""
    }
    
    // MARK: - Management
    
    func clearChat() {
        messages.removeAll()
        currentStreamingMessage = ""
        errorMessage = nil
    }
}
