import Foundation
import Observation

/// ViewModel for model management — v1 simplified.
/// Single model at a time, USB import via document picker.
@MainActor
@Observable
final class ModelViewModel {
    
    // MARK: - State
    
    var availableModels: [ModelConfig] = []
    var discoveredModels: [DiscoveredModel] = []
    var isScanning: Bool = false
    var isImporting: Bool = false
    var importProgress: Double = 0
    var importError: String?
    var memoryUsageGB: Float = 0
    var showDocumentPicker: Bool = false
    
    // MARK: - Services
    
    var services: ServiceContainer?
    
    // MARK: - Initialization
    
    func loadModelState() async {
        guard let services else { return }
        availableModels = await services.modelManager.discoverModels()
        memoryUsageGB = await services.modelManager.memoryUsage()
    }
    
    // MARK: - Model Operations
    
    func loadTextModel() async {
        guard let services else { return }
        do {
            let config = try await services.ensureTextModelLoaded()
            availableModels = await services.modelManager.discoverModels()
        } catch {
            importError = error.localizedDescription
        }
    }
    
    func loadVisionModel() async {
        guard let services else { return }
        do {
            let config = try await services.ensureVisionModelLoaded()
            availableModels = await services.modelManager.discoverModels()
        } catch {
            importError = error.localizedDescription
        }
    }
    
    func unloadModel() {
        services?.unloadModel()
        memoryUsageGB = 0
    }
    
    // MARK: - USB Import
    
    func scanPickedLocations(urls: [URL]) async {
        guard let services else { return }
        isScanning = true
        importError = nil
        defer { isScanning = false }
        
        var found: [DiscoveredModel] = []
        
        for url in urls {
            let models = await services.usbImportService.scanForModels(in: url)
            found.append(contentsOf: models)
        }
        
        discoveredModels = found
        
        if found.isEmpty {
            importError = "No MLX model directories found. Models should contain .safetensors files and config.json."
        }
    }
    
    func importAllDiscovered() async {
        guard let services, !discoveredModels.isEmpty else { return }
        isImporting = true
        importProgress = 0
        importError = nil
        
        do {
            try await services.usbImportService.importAll(
                models: discoveredModels,
                modelManager: services.modelManager
            ) { @Sendable progress in
                Task { @MainActor in
                    self.importProgress = progress
                }
            }
            
            availableModels = await services.modelManager.discoverModels()
            discoveredModels.removeAll()
        } catch {
            importError = error.localizedDescription
        }
        
        isImporting = false
    }
}
