import Foundation
import Observation
import SwiftData

/// ViewModel for the chat interface
/// Uses shared ServiceContainer for global actor service instances
@MainActor
@Observable
final class ChatViewModel {
    
    // MARK: - Published State
    
    var messages: [ChatMessage] = []
    var currentStreamingMessage: String = ""
    var isGenerating: Bool = false
    var currentTier: RoutingTier = .fast
    var errorMessage: String?
    var conversation: Conversation?
    
    // MARK: - Services (shared via ServiceContainer)
    
    /// Injected by the view hierarchy — set before use
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
        
        do {
            // 1. Route to determine tier
            let decision = await services.autoRouter.route(
                prompt: text,
                hasImage: image != nil,
                conversationLength: messages.count,
                memoryPressure: appState?.memoryPressure ?? .normal,
                thermalState: appState?.thermalState ?? .nominal,
                batteryLevel: appState?.batteryLevel ?? 1.0,
                isOnline: appState?.isOnline ?? false,
                hasAPIKey: appState?.hasAPIKey ?? false,
                forcedTier: appState?.routingMode == .manual ? appState?.activeTier : nil
            )
            
            currentTier = decision.tier
            appState?.activeTier = decision.tier
            
            // 2. Optionally augment with RAG
            var usedRAG = false
            let finalPrompt: String
            if decision.tier.isOnDevice {
                let augmented = await services.ragService.augmentPrompt(userPrompt: text)
                usedRAG = augmented != text
                finalPrompt = augmented
            } else {
                finalPrompt = text
            }
            
            // 3. Build message list with ALIVE system prompt first (Fast/Moderate)
            var inferenceMessages = messages
            if decision.tier.isOnDevice {
                let sys = ChatMessage(
                    role: .system,
                    content: AliveSystemPrompt.full(tier: decision.tier, hasRAG: usedRAG)
                )
                // Drop any prior system rows, prepend one canonical prompt
                inferenceMessages.removeAll { $0.role == .system }
                // Last user may need RAG-augmented content for this turn
                if usedRAG, let lastIdx = inferenceMessages.indices.last,
                   inferenceMessages[lastIdx].role == .user {
                    inferenceMessages[lastIdx] = ChatMessage(
                        role: .user,
                        content: finalPrompt,
                        hasImage: image != nil,
                        imageData: image
                    )
                }
                inferenceMessages.insert(sys, at: 0)
            }
            
            // 4. Run inference based on tier
            let stream: AsyncThrowingStream<String, Error>
            
            switch decision.tier {
            case .fast, .moderate:
                guard let modelConfig = decision.tier.textModel else {
                    throw ModelError.noModelForTier(decision.tier)
                }
                
                // Ensure model is loaded via shared service container
                let model = try await services.ensureTextModelLoaded(tier: decision.tier)
                
                // If there's an image, use vision pipeline
                if let imageData = image {
                    stream = await services.inferenceEngine.generateVision(
                        image: imageData,
                        prompt: finalPrompt,
                        model: model
                    )
                } else {
                    let msgs = messages; stream = await services.inferenceEngine.generate(
                        messages: msgs,
                        model: model
                    )
                }
                
            case .pro:
                let gmsgs = messages; stream = await services.grokService.send(
                    messages: gmsgs,
                    stream: true
                )
                
            case .none:
                throw ModelError.noModelForTier(.none)
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
                tierUsed: decision.tier.rawValue
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
    
    func loadConversation(_ conversation: Conversation) {
        self.conversation = conversation
        self.messages = conversation.messages
    }
    
    // MARK: - Tier Switching
    
    func switchTier(_ tier: RoutingTier) {
        appState?.activeTier = tier
        appState?.routingMode = .manual
    }
    
    func enableAutoRouting() {
        appState?.routingMode = .auto
    }
}
