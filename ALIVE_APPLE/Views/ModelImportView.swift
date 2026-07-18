import SwiftUI

/// Dashboard and model-import view combined.
///
/// USB import flow:
/// 1. User taps "Browse Files" or "Browse Folder"
/// 2. iOS document picker opens (Files app, iCloud, USB drives)
/// 3. Selected models are scanned and displayed
/// 4. User confirms import
struct ModelImportView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services
    @State private var modelVM = ModelViewModel()
    @State private var selectedModels: Set<UUID> = []
    
    var body: some View {
        List {
            // MARK: - Current Status
            Section("Current Tier") {
                HStack {
                    Circle()
                        .fill(modelVM.currentTier.color)
                        .frame(width: 12, height: 12)
                    Text(modelVM.currentTier.label)
                        .font(.headline)
                    Spacer()
                    Text(modelVM.memoryUsageGB > 0
                         ? String(format: "%.1f GB used", modelVM.memoryUsageGB)
                         : "No models loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Memory gauge
                if modelVM.memoryUsageGB > 0 {
                    MemoryGaugeView(usedGB: modelVM.memoryUsageGB)
                        .frame(height: 40)
                }
            }
            
            // MARK: - Tier Selection
            Section("Select Tier") {
                ForEach(RoutingTier.allCases, id: \.self) { tier in
                    Button(action: {
                        Task { await modelVM.setTier(tier) }
                    }) {
                        HStack {
                            Image(systemName: tier.systemImage)
                                .foregroundColor(tier.color)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tier.label)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(tier.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if modelVM.currentTier == tier {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(tier.color)
                            }
                        }
                    }
                }
            }
            
            // MARK: - Model Import (Document Picker)
            Section("Import Models") {
                VStack(spacing: 12) {
                    // Browse buttons
                    HStack(spacing: 16) {
                        Button(action: { modelVM.showDocumentPicker = true }) {
                            Label("Browse Files", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Button(action: { modelVM.showDirectoryPicker = true }) {
                            Label("Browse Folder", systemImage: "folder.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Select .gguf, .mlx, or .mlmodelc model files from Files, iCloud, or a connected USB-C drive.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
                .padding(.vertical, 4)
                
                // Scanning state
                if modelVM.isScanningUSB {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Scanning selected files...")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Discovered models
                if !modelVM.discoveredUSBModels.isEmpty {
                    ForEach(modelVM.discoveredUSBModels) { model in
                        DiscoveredModelRow(
                            model: model,
                            isSelected: selectedModels.contains(model.id)
                        ) {
                            if selectedModels.contains(model.id) {
                                selectedModels.remove(model.id)
                            } else {
                                selectedModels.insert(model.id)
                            }
                        }
                    }
                }
                
                // Import progress
                if modelVM.isImporting {
                    VStack(spacing: 8) {
                        ProgressView(value: modelVM.importProgress)
                        Text("Importing... \(Int(modelVM.importProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Import button (shown when models are discovered and not currently importing)
                if !modelVM.discoveredUSBModels.isEmpty && !modelVM.isImporting {
                    Button(action: {
                        let selected = modelVM.discoveredUSBModels.filter { selectedModels.contains($0.id) }
                        Task { await modelVM.importSelectedModels(selected) }
                    }) {
                        Label(
                            selectedModels.isEmpty
                            ? "Import All (\(modelVM.discoveredUSBModels.count) models)"
                            : "Import Selected (\(selectedModels.count) models)",
                            systemImage: "square.and.arrow.down.fill"
                        )
                    }
                    .disabled(selectedModels.isEmpty && modelVM.discoveredUSBModels.isEmpty)
                }
                
                // Error display
                if let error = modelVM.importError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // MARK: - Available Models
            Section("Imported Models") {
                if modelVM.availableModels.isEmpty {
                    VStack(spacing: 8) {
                        Text("No models imported yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Tap \"Browse Files\" to select model files from your device or USB drive.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    ForEach(modelVM.availableModels) { model in
                        ModelRow(model: model)
                    }
                }
            }
            
            // MARK: - Actions
            Section {
                Button(role: .destructive, action: {
                    Task { await modelVM.unloadAllModels() }
                }) {
                    Label("Unload All Models", systemImage: "xmark.circle")
                }
                .disabled(modelVM.memoryUsageGB == 0)
            }
        }
        .navigationTitle("Models")
        .onAppear {
            modelVM.services = services
            Task { await modelVM.loadModelState() }
        }
        // Document picker for individual model files
        .sheet(isPresented: $modelVM.showDocumentPicker) {
            ModelDocumentPicker { urls in
                Task { await modelVM.scanPickedFiles(urls: urls) }
            }
        }
        // Directory picker for folder scanning
        .sheet(isPresented: $modelVM.showDirectoryPicker) {
            ModelDirectoryPicker { url in
                Task { await modelVM.scanPickedDirectory(url: url) }
            }
        }
    }
}

// MARK: - Subviews

struct MemoryGaugeView: View {
    let usedGB: Float
    let totalGB: Float = 8.0
    
    var usageColor: Color {
        let pct = usedGB / totalGB
        if pct > 0.85 { return .red }
        if pct > 0.7 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(usageColor)
                        .frame(width: geo.size.width * CGFloat(usedGB / totalGB), height: 6)
                }
            }
            HStack {
                Text(String(format: "%.1f GB free", totalGB - usedGB))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f / %.1f GB", usedGB, totalGB))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ModelRow: View {
    let model: ModelConfig
    
    var body: some View {
        HStack {
            Image(systemName: model.modelType == .text ? "text.bubble" : "camera.macro")
                .foregroundColor(model.tier.color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(.body)
                Text("\(model.quant) · \(model.formattedSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(model.isLoaded ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                Text(model.isLoaded ? "Loaded" : "Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DiscoveredModelRow: View {
    let model: DiscoveredModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.fileName)
                        .font(.body)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(model.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let tier = model.matchedConfig?.tier {
                            Text(tier.label)
                                .font(.caption2)
                                .foregroundColor(tier.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tier.color.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ModelImportView()
            .environment(AppState())
            .environment(ServiceContainer())
            .preferredColorScheme(.dark)
    }
}
