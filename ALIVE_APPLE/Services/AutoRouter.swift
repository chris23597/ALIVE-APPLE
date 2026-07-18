import Foundation

/// Intelligent offline/online auto-router for model tier selection
actor AutoRouter {
    
    // MARK: - Configuration
    
    private let complexityThreshold: Float = 0.5
    private let maxRoutingHistory: Int = 1000
    
    // MARK: - State
    
    private var routingHistory: [RoutingRecord] = []
    
    // MARK: - Main Routing Entry Point
    
    /// Determine the best tier for a given prompt and system state
    func route(
        prompt: String,
        hasImage: Bool,
        conversationLength: Int,
        memoryPressure: MemoryPressure,
        thermalState: ThermalState,
        batteryLevel: Float,
        isOnline: Bool,
        hasAPIKey: Bool,
        forcedTier: RoutingTier?
    ) -> RoutingDecision {
        
        let inputs = RoutingInputs(
            prompt: prompt,
            hasImage: hasImage,
            conversationLength: conversationLength,
            memoryPressure: memoryPressure,
            thermalState: thermalState,
            batteryLevel: batteryLevel,
            isOnline: isOnline,
            hasAPIKey: hasAPIKey,
            forcedTier: forcedTier
        )
        
        let tier = decideTier(inputs: inputs)
        let confidence = calculateConfidence(inputs: inputs, chosen: tier)
        let reason = explainDecision(inputs: inputs, tier: tier)
        
        return RoutingDecision(
            tier: tier,
            confidence: confidence,
            reason: reason
        )
    }
    
    // MARK: - Decision Logic
    
    func decideTier(inputs: RoutingInputs) -> RoutingTier {
        // 1. User override always wins
        if let forced = inputs.forcedTier {
            return forced
        }
        
        // 2. Hard constraints — safety first
        if inputs.thermalState == .critical || inputs.memoryPressure == .critical {
            return .fast
        }
        
        if inputs.batteryLevel < 0.10 && !inputs.hasImage {
            return .fast
        }
        
        // 3. Compute complexity
        let complexity = complexityScore(
            prompt: inputs.prompt,
            conversationLength: inputs.conversationLength
        )
        
        // 4. Deep analysis detection (user signals they want thorough)
        let wantsDeep = inputs.prompt.lowercased().contains("deep analysis") ||
                        inputs.prompt.lowercased().contains("thorough") ||
                        inputs.prompt.lowercased().contains("in detail") ||
                        inputs.prompt.lowercased().contains("comprehensive") ||
                        inputs.prompt.lowercased().contains("detailed analysis")
        
        // 5. Context overflow detection
        let estimatedTokens = inputs.prompt.utf8.count / 3
        let contextOverflow = inputs.conversationLength > 20 && estimatedTokens > 4000
        
        // 6. Check Pro tier availability
        if inputs.isOnline && inputs.hasAPIKey {
            // Very complex or very long conversations → cloud
            if complexity > 0.85 {
                return .pro
            }
            if inputs.conversationLength > 30 {
                return .pro
            }
            // Context overflow → cloud has bigger context
            if contextOverflow {
                return .pro
            }
            // Deep analysis requested → Pro is best
            if wantsDeep && inputs.hasImage {
                return .pro
            }
            // Complex vision → Grok has excellent vision capabilities
            if inputs.hasImage && complexity > 0.6 {
                return .pro
            }
        }
        
        // 7. On-device routing
        if complexity > complexityThreshold || inputs.hasImage || wantsDeep {
            // Check if system can handle moderate tier
            if inputs.thermalState == .serious {
                return .fast  // Too hot for moderate
            }
            if inputs.memoryPressure == .warning {
                return .fast  // Memory tight
            }
            if inputs.batteryLevel < 0.25 {
                return .fast  // Battery low
            }
            return .moderate
        }
        
        // 8. Default: Fast tier for everything else
        return .fast
    }
    
    // MARK: - Complexity Scoring
    
    func complexityScore(prompt: String, conversationLength: Int) -> Float {
        var score: Float = 0.0
        let lowerPrompt = prompt.lowercased()
        
        // Length-based signals
        if prompt.count > 500 { score += 0.15 }
        if prompt.count > 1000 { score += 0.15 }
        if prompt.count > 2000 { score += 0.10 }
        if conversationLength > 10 { score += 0.15 }
        if conversationLength > 20 { score += 0.10 }
        
        // Complex keywords
        let complexKeywords = [
            "explain", "analyze", "compare", "contrast", "evaluate",
            "reason", "proof", "calculate", "solve", "debug",
            "code", "implement", "architecture", "design", "optimize",
            "why does", "how does", "what is the relationship",
            "step by step", "in detail", "comprehensive",
            "implications", "trade-off", "pros and cons"
        ]
        
        let keywordMatches = complexKeywords.filter { lowerPrompt.contains($0) }
        score += Float(keywordMatches.count) * 0.05
        
        // Code/math detection
        if lowerPrompt.contains("```") ||
           lowerPrompt.contains("func ") ||
           lowerPrompt.contains("def ") ||
           lowerPrompt.contains("class ") ||
           lowerPrompt.contains("function") ||
           lowerPrompt.contains("algorithm") {
            score += 0.2
        }
        
        // Multi-part question detection
        let questionMarks = prompt.filter { $0 == "?" }.count
        if questionMarks > 1 { score += 0.1 }
        if questionMarks > 3 { score += 0.1 }
        
        // Vision-specific keywords (benefit from stronger VLM)
        let visionKeywords = [
            "identify this", "what plant", "what species", "what flower",
            "what kind of", "read this", "ocr", "scan this",
            "describe this image", "what's in this photo"
        ]
        if visionKeywords.contains(where: { lowerPrompt.contains($0) }) {
            score += 0.3
        }
        
        return min(score, 1.0)
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(inputs: RoutingInputs, chosen: RoutingTier) -> Float {
        // Higher confidence when:
        // - System is in good state
        // - Decision is unambiguous
        
        var confidence: Float = 0.7  // Base confidence
        
        // Boost for good system state
        if inputs.thermalState == .nominal { confidence += 0.05 }
        if inputs.memoryPressure == .low { confidence += 0.05 }
        if inputs.batteryLevel > 0.5 { confidence += 0.05 }
        
        // Boost for clear decisions
        let complexity = complexityScore(prompt: inputs.prompt, conversationLength: inputs.conversationLength)
        if chosen == .fast && complexity < 0.3 { confidence += 0.15 }
        if chosen == .moderate && complexity > 0.6 { confidence += 0.1 }
        
        // Penalty for constrained decisions
        if inputs.thermalState == .serious { confidence -= 0.1 }
        if inputs.memoryPressure == .warning { confidence -= 0.1 }
        
        return min(max(confidence, 0.0), 1.0)
    }
    
    // MARK: - Decision Explanation
    
    private func explainDecision(inputs: RoutingInputs, tier: RoutingTier) -> String {
        switch tier {
        case .fast:
            if inputs.thermalState == .critical {
                return "Device too hot — using Fast tier for safety"
            }
            if inputs.memoryPressure == .critical {
                return "Memory critical — using Fast tier"
            }
            if inputs.batteryLevel < 0.1 {
                return "Battery very low — using Fast tier to conserve power"
            }
            return "Simple query — Fast tier is sufficient"
            
        case .moderate:
            let complexity = complexityScore(prompt: inputs.prompt, conversationLength: inputs.conversationLength)
            if inputs.hasImage {
                return "Vision analysis requested — Moderate VLM provides best accuracy"
            }
            return "Complex query (score: \(Int(complexity * 100))%) — Moderate tier for deeper reasoning"
            
        case .pro:
            if inputs.conversationLength > 30 {
                return "Long conversation — Pro tier for context-heavy reasoning"
            }
            return "Very complex query — routing to Pro tier (Grok)"
            
        case .none:
            return "No models available"
        }
    }
    
    // MARK: - History Tracking
    
    func recordDecision(_ decision: RoutingDecision, inputs: RoutingInputs) {
        let record = RoutingRecord(
            timestamp: Date(),
            promptHash: String(inputs.prompt.hash),
            decidedTier: decision.tier,
            complexityScore: complexityScore(
                prompt: inputs.prompt,
                conversationLength: inputs.conversationLength
            ),
            userOverrode: inputs.forcedTier != nil,
            userChoseTier: inputs.forcedTier,
            responseTimeMs: nil,
            userRatedHelpful: nil
        )
        
        routingHistory.append(record)
        
        // Trim history
        if routingHistory.count > maxRoutingHistory {
            routingHistory.removeFirst(routingHistory.count - maxRoutingHistory)
        }
    }
}

// MARK: - Supporting Types

struct RoutingRecord: Codable {
    let timestamp: Date
    let promptHash: String
    let decidedTier: RoutingTier
    let complexityScore: Float
    let userOverrode: Bool
    let userChoseTier: RoutingTier?
    let responseTimeMs: Int?
    let userRatedHelpful: Bool?
}
