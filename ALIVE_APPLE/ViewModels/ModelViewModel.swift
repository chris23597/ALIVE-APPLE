import Foundation
import Observation

/// ViewModel for model management
/// Uses shared ServiceContainer for global actor service instances
@MainActor
@Observable
final class ModelViewModel {
    
    // MARK: - State
    
    var availableModels: [ModelConfig] = []
    var loadedModels: [ModelConfig] = []
    var discoveredUSBModels: [DiscoveredModel] = []
    var isScanningUSB: Bool = false
    var isImporting: Bool = false
    var importProgress: Double = 0
    var importError: String?
    var currentTier: RoutingTier = .none
    var memoryUsageGB: Float = 0
    
    // MARK: - Services (shared via ServiceContainer)
    
    /// Injected by the view hierarchy — set before use
    var services: ServiceContainer?
    
    // MARK: - Initialization
    
    func loadModelState() async {
        guard let services else { return }
        
        availableModels = await services.modelManager.discoverModels()
        
        // Auto-load Fast tier if models available and nothing loaded
        if !availableModels.isEmpty && loadedModels.isEmpty {
            do {
                let config = try await services.ensureTextModelLoaded(tier: .fast)
                loadedModels = [config]
                currentTier = .fast
            } catch {
                print("Auto-load Fast tier failed: \(error)")
            }
        }
        
        memoryUsageGB = await services.modelManager.memoryUsage()
    }
    
    // MARK: - Model Operations
    
    func setTier(_ tier: RoutingTier) async {
        guard let services else { return }
        currentTier = tier
        
        switch tier {
        case .fast, .moderate:
            do {
                let config = try await services.ensureTextModelLoaded(tier: tier)
                loadedModels = [config]
            } catch {
                importError = error.localizedDescription
            }
        case .pro:
            // Pro uses cloud — no model to load
            loadedModels = []
        case .none:
            await services.modelManager.unloadAll()
            loadedModels = []
        }
        
        memoryUsageGB = await services.modelManager.memoryUsage()
    }
    
    func unloadAllModels() async {
        guard let services else { return }
        await services.modelManager.unloadAll()
        loadedModels = []
        currentTier = .none
        memoryUsageGB = 0
    }
    
    // MARK: - USB Import
    
    func scanUSBDrive() async {
        guard let services else { return }
        isScanningUSB = true
        defer { isScanningUSB = false }
        
        guard let driveURL = await services.usbImportService.detectUSBDrive() else {
            importError = "No USB drive detected"
            return
        }
        
        guard await services.usbImportService.verifyExFATFormat(volumeURL: driveURL) else {
            importError = "Drive must be formatted as exFAT"
            return
        }
        
        discoveredUSBModels = await services.usbImportService.scanForModels(in: driveURL)
        
        if discoveredUSBModels.isEmpty {
            importError = "No compatible model files found on USB drive"
        }
    }
    
    func importSelectedModels(_ models: [DiscoveredModel]) async {
        guard let services else { return }
        isImporting = true
        importProgress = 0
        importError = nil
        
        do {
            try await services.usbImportService.importAll(
                models: models,
                modelManager: services.modelManager
            ) { progress in
                Task { @MainActor in
                    self.importProgress = progress
                }
            }
            
            // Refresh available models
            availableModels = await services.modelManager.discoverModels()
            
        } catch {
            importError = error.localizedDescription
        }
        
        isImporting = false
    }
    
    func importAllModels() async {
        await importSelectedModels(discoveredUSBModels)
    }
}
