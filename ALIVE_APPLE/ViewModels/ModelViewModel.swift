import Foundation
import Observation

/// ViewModel for model management.
/// Uses shared ServiceContainer for global actor service instances.
///
/// USB import flow:
/// 1. User taps "Browse Files" → opens UIDocumentPicker
/// 2. Selected URLs are passed to scanPickedURLs()
/// 3. Models are displayed and user confirms import
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
    
    /// Controls whether the document picker sheet is shown
    var showDocumentPicker: Bool = false
    /// Controls whether the directory picker sheet is shown
    var showDirectoryPicker: Bool = false
    
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
    
    // MARK: - USB Import (Document Picker)
    
    /// Called when user selects model files via the document picker.
    /// Scans the selected URLs for valid model files.
    func scanPickedFiles(urls: [URL]) async {
        guard let services else { return }
        isScanningUSB = true
        importError = nil
        defer { isScanningUSB = false }
        
        var found: [DiscoveredModel] = []
        
        for url in urls {
            // For individual file picks
            if await services.usbImportService.isModelFile(url) {
                let fileName = url.lastPathComponent
                let fileSize: Int64
                if let attrs = try? url.resourceValues(forKeys: [.fileSizeKey]),
                   let size = attrs.fileSize {
                    fileSize = Int64(size)
                } else {
                    fileSize = 0
                }
                
                let model = DiscoveredModel(
                    url: url,
                    fileName: fileName,
                    fileSize: fileSize,
                    matchedConfig: nil  // Will be matched during import
                )
                found.append(model)
            }
        }
        
        discoveredUSBModels = found
        
        if found.isEmpty {
            importError = "No compatible model files (.gguf, .mlx, .mlmodelc) found"
        }
    }
    
    /// Called when user selects a directory via the directory picker.
    /// Recursively scans the directory for model files.
    func scanPickedDirectory(url: URL) async {
        guard let services else { return }
        isScanningUSB = true
        importError = nil
        defer { isScanningUSB = false }
        
        let found = await services.usbImportService.scanForModels(in: url)
        discoveredUSBModels = found
        
        if found.isEmpty {
            importError = "No compatible model files found in the selected folder"
        }
    }
    
    /// Import the selected discovered models
    func importSelectedModels(_ models: [DiscoveredModel]) async {
        guard let services else { return }
        isImporting = true
        importProgress = 0
        importError = nil
        
        do {
            try await services.usbImportService.importAll(
                models: models,
                modelManager: services.modelManager
            ) { @Sendable progress in
                Task { @MainActor in
                    self.importProgress = progress
                }
            }
            
            // Refresh available models
            availableModels = await services.modelManager.discoverModels()
            discoveredUSBModels.removeAll()
            
        } catch {
            importError = error.localizedDescription
        }
        
        isImporting = false
    }
    
    func importAllModels() async {
        await importSelectedModels(discoveredUSBModels)
    }
}
