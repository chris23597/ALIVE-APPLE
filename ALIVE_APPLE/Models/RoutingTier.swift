import SwiftUI

/// Three-tier routing model: Fast → Moderate → Pro
enum RoutingTier: String, CaseIterable, Codable {
    case fast = "Fast"
    case moderate = "Moderate"
    case pro = "Pro"
    case none = "None"
    
    var label: String {
        rawValue
    }
    
    var color: Color {
        switch self {
        case .fast:     return Color(red: 0.298, green: 0.686, blue: 0.314)  // #4CAF50
        case .moderate: return Color(red: 1.0, green: 0.596, blue: 0.0)       // #FF9800
        case .pro:      return Color(red: 0.129, green: 0.588, blue: 0.953)   // #2196F3
        case .none:     return Color(red: 0.957, green: 0.263, blue: 0.212)   // #F44336
        }
    }
    
    var systemImage: String {
        switch self {
        case .fast:     return "bolt.fill"
        case .moderate: return "brain.head.profile"
        case .pro:      return "cloud.fill"
        case .none:     return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .fast:
            return "Fast responses · On-device · Always ready"
        case .moderate:
            return "Deeper reasoning · On-device · Loads in seconds"
        case .pro:
            return "Maximum capability · Grok API · Requires internet"
        case .none:
            return "No model loaded"
        }
    }
    
    var textModel: ModelConfig? {
        switch self {
        case .fast:     return .phi4Mini
        case .moderate: return .qwen25_7b
        case .pro:      return nil  // Cloud API
        case .none:     return nil
        }
    }
    
    var visionModel: ModelConfig? {
        switch self {
        case .fast:     return .smolVLM2
        case .moderate: return .qwen25VL_7b
        case .pro:      return nil  // Cloud API handles vision natively
        case .none:     return nil
        }
    }
    
    var requiresInternet: Bool {
        self == .pro
    }
    
    var isOnDevice: Bool {
        self == .fast || self == .moderate
    }
}

/// Result from the AutoRouter
struct RoutingDecision: Codable {
    let tier: RoutingTier
    let confidence: Float        // 0.0 ... 1.0
    let reason: String
    
    var confidencePercent: Int {
        Int(confidence * 100)
    }
}

/// Input signals for routing decision
struct RoutingInputs {
    let prompt: String
    let hasImage: Bool
    let conversationLength: Int
    let memoryPressure: MemoryPressure
    let thermalState: ThermalState
    let batteryLevel: Float      // 0.0 ... 1.0
    let isOnline: Bool
    let hasAPIKey: Bool
    let forcedTier: RoutingTier?
}
