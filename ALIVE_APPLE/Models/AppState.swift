import Foundation
import Observation

/// Global application state — observed by all views.
/// v1 simplified: single Fast tier, no API key, no RAG, no routing.
@MainActor
@Observable
final class AppState {
    
    // MARK: - System State
    var isOnline: Bool = false
    var memoryPressure: MemoryPressure = .normal
    var thermalState: ThermalState = .nominal
    var batteryLevel: Float = 1.0
    var isCharging: Bool = false
    
    // MARK: - Models
    var loadedModel: ModelConfig?
    var availableModels: [ModelConfig] = []
    var isModelLoading: Bool = false
    var modelLoadProgress: Double = 0.0
    
    // MARK: - UI State
    var selectedTab: Tab = .chat
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
    
    var currentModelDisplayName: String {
        loadedModel?.name ?? "No Model"
    }
    
    var memoryDescription: String {
        switch memoryPressure {
        case .low:      return "Plenty free"
        case .normal:   return "Normal"
        case .warning:  return "Running low"
        case .critical: return "Critical — unload model"
        }
    }
    
    var thermalDescription: String {
        switch thermalState {
        case .nominal:  return "Cool"
        case .fair:     return "Warm"
        case .serious:  return "Hot — pause inference"
        case .critical: return "Very hot — stop"
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
