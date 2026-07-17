import Foundation
import Observation

/// ViewModel for Settings
@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - State
    
    var apiKey: String = ""
    var isKeyValid: Bool = false
    var isKeyMasked: Bool = true
    var maskedKey: String = ""
    var isVerifying: Bool = false
    var verificationError: String?
    
    var autoPlayVoice: Bool = false
    var hapticFeedback: Bool = true
    var defaultTemperature: Float = 0.7
    var maxTokens: Int = 4096
    var routingMode: AppState.RoutingMode = .auto
    
    // MARK: - Services
    
    private let keychain = KeychainManager()
    
    // MARK: - Initialization
    
    func loadSettings() async {
        // Load API key state
        isKeyValid = await keychain.hasKey()
        if isKeyValid {
            maskedKey = (try? await keychain.maskedKey()) ?? "••••"
        }
        
        // Load preferences from UserDefaults
        autoPlayVoice = UserDefaults.standard.bool(forKey: "auto_play_voice")
        hapticFeedback = UserDefaults.standard.bool(forKey: "haptic_feedback")
        defaultTemperature = UserDefaults.standard.float(forKey: "default_temperature")
        maxTokens = UserDefaults.standard.integer(forKey: "max_tokens")
        
        if defaultTemperature == 0 { defaultTemperature = 0.7 }
        if maxTokens == 0 { maxTokens = 4096 }
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey() async {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isVerifying = true
        verificationError = nil
        
        do {
            // Validate key first
            let isValid = try await keychain.validateKey(apiKey)
            
            if isValid {
                try await keychain.saveKey(apiKey)
                isKeyValid = true
                maskedKey = try await keychain.maskedKey()
                apiKey = ""
            } else {
                verificationError = "Invalid API key — please check and try again"
            }
        } catch {
            verificationError = error.localizedDescription
        }
        
        isVerifying = false
    }
    
    func removeAPIKey() async {
        do {
            try await keychain.deleteKey()
            isKeyValid = false
            maskedKey = ""
            apiKey = ""
        } catch {
            print("Failed to delete key: \(error)")
        }
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
        // Export all conversations as JSON
        // In production: fetch from SwiftData context
        return "{}"
    }
    
    func clearAllChats() {
        // In production: delete from SwiftData
    }
    
    func clearModelCache() {
        // Delete all imported models
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsURL = documents.appendingPathComponent("Models")
        try? FileManager.default.removeItem(at: modelsURL)
    }
}
