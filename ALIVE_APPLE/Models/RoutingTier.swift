import Foundation
import SwiftUI

/// Simplified v1 routing — single Fast tier only (on-device).
/// Kept as enum for forward-compatibility with v2 tiers.
enum RoutingTier: String, CaseIterable, Codable {
    case fast = "Fast"
    case none = "None"
    
    var label: String { rawValue }
    
    var color: Color {
        switch self {
        case .fast: return Color(red: 0.298, green: 0.686, blue: 0.314)
        case .none: return Color(red: 0.957, green: 0.263, blue: 0.212)
        }
    }
    
    var systemImage: String {
        switch self {
        case .fast: return "bolt.fill"
        case .none: return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .fast: return "Fast responses · On-device · Phi-4 Mini 3.8B"
        case .none: return "No model loaded"
        }
    }
    
    var textModel: ModelConfig? {
        switch self {
        case .fast: return .phi4Mini
        case .none: return nil
        }
    }
    
    var visionModel: ModelConfig? {
        switch self {
        case .fast: return .smolVLM2
        case .none: return nil
        }
    }
    
    var requiresInternet: Bool { false }
    var isOnDevice: Bool { self == .fast }
}
