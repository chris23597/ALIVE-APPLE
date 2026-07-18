import Foundation
import Observation

/// Global application state — observed by all views
@MainActor
@Observable
final class AppState {
    
    // MARK: - Routing
    var activeTier: RoutingTier = .none
    var routingMode: RoutingMode = .auto  // .auto | .manual
    
    enum RoutingMode: String, Codable {
        case auto
        case manual
    }
    
    // MARK: - System State
    var isOnline: Bool = false
    var memoryPressure: MemoryPressure = .normal
    var thermalState: ThermalState = .nominal
    var batteryLevel: Float = 1.0
    var isCharging: Bool = false
    
    // MARK: - Models
    var loadedModels: [ModelConfig] = []
    var availableModels: [ModelConfig] = []
    var isModelLoading: Bool = false
    var modelLoadProgress: Double = 0.0  // 0.0 ... 1.0
    
    // MARK: - Pro Tier
    var hasAPIKey: Bool = false
    var isProAvailable: Bool {
        isOnline && hasAPIKey
    }
    
    // MARK: - RAG State
    var ragChunkCount: Int = 0
    var ragEmbeddingCoverage: Double = 0.0
    var ragIsIndexing: Bool = false
    
    // MARK: - UI State
    var selectedTab: Tab = .chat
    var showSettings: Bool = false
    var errorToast: String?
    var infoToast: String?
    
    enum Tab: String, CaseIterable {
        case chat = "Chat"
        case vision = "Vision"
        case models = "Models"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .chat:     return "message.fill"
            case .vision:   return "camera.fill"
            case .models:   return "square.and.arrow.down.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Computed
    
    var availableTiers: [RoutingTier] {
        var tiers: [RoutingTier] = [.fast]
        if availableModels.contains(where: { $0.tier == .moderate }) {
            tiers.append(.moderate)
        }
        if isProAvailable {
            tiers.append(.pro)
        }
        tiers.append(.none)
        return tiers
    }
    
    var currentModelDisplayName: String {
        switch activeTier {
        case .fast:     return "Phi-4 Mini 3.8B"
        case .moderate: return "Qwen2.5 7B"
        case .pro:      return "Grok (xAI)"
        case .none:     return "No Model"
        }
    }
    
    var memoryDescription: String {
        switch memoryPressure {
        case .low:      return "Plenty free"
        case .normal:   return "Normal"
        case .warning:  return "Running low"
        case .critical: return "Critical — unload models"
        }
    }
    
    var thermalDescription: String {
        switch thermalState {
        case .nominal:  return "Cool"
        case .fair:     return "Warm"
        case .serious:  return "Hot — Fast tier only"
        case .critical: return "Very hot — pause inference"
        }
    }
    
    // MARK: - Toast Helpers
    
    func showError(_ message: String) {
        errorToast = message
        Task {
            try? await Task.sleep(for: .seconds(4))
            errorToast = nil
        }
    }
    
    func showInfo(_ message: String) {
        infoToast = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            infoToast = nil
        }
    }
}

// MARK: - System State Enums

enum MemoryPressure: String, Codable {
    case low
    case normal
    case warning
    case critical
}

enum ThermalState: String, Codable {
    case nominal
    case fair
    case serious
    case critical
}
