import Foundation
import Observation

/// ViewModel for Settings — v1 simplified.
/// No API key management (fully offline), no RAG.
@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - State
    
    var autoPlayVoice: Bool = false
    var hapticFeedback: Bool = true
    var defaultTemperature: Float = 0.7
    var maxTokens: Int = 2048
    
    // MARK: - Initialization
    
    func loadSettings() async {
        autoPlayVoice = UserDefaults.standard.bool(forKey: "auto_play_voice")
        hapticFeedback = UserDefaults.standard.bool(forKey: "haptic_feedback")
        defaultTemperature = UserDefaults.standard.float(forKey: "default_temperature")
        maxTokens = UserDefaults.standard.integer(forKey: "max_tokens")
        
        if defaultTemperature == 0 { defaultTemperature = 0.7 }
        if maxTokens == 0 { maxTokens = 2048 }
    }
    
    // MARK: - Preferences
    
    func savePreference(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func toggleAutoPlayVoice() {
        autoPlayVoice.toggle()
        savePreference(key: "auto_play_voice", value: autoPlayVoice)
    }
    
    func toggleHapticFeedback() {
        hapticFeedback.toggle()
        savePreference(key: "haptic_feedback", value: hapticFeedback)
    }
    
    // MARK: - Data Management
    
    func exportChats() -> String {
        return "{}"
    }
    
    func clearAllChats() {
        // In production: delete from SwiftData
    }
    
    func clearModelCache() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsURL = documents.appendingPathComponent("Models")
        try? FileManager.default.removeItem(at: modelsURL)
    }
}
