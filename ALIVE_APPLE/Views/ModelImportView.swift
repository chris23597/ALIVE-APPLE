import SwiftUI

/// Dashboard and model-import view combined
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
            
            // MARK: - USB Import
            Section("USB Import") {
                if modelVM.isScanningUSB {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Scanning USB drive...")
                            .foregroundColor(.secondary)
                    }
                } else if modelVM.discoveredUSBModels.isEmpty {
                    Button(action: {
                        Task { await modelVM.scanUSBDrive() }
                    }) {
                        Label("Scan for Models", systemImage: "magnifyingglass")
                    }
                } else {
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
                    
                    if modelVM.isImporting {
                        VStack(spacing: 8) {
                            ProgressView(value: modelVM.importProgress)
                            Text("Importing... \(Int(modelVM.importProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
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
                }
                
                if let error = modelVM.importError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // MARK: - Available Models
            Section("Imported Models") {
                if modelVM.availableModels.isEmpty {
                    Text("No models imported. Connect a USB drive to get started.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                Text("\(model.parameterCount) · \(model.quant) · \(model.formattedSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(model.isLoaded ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 10, height: 10)
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
                    .foregroundColor(isSelected ? .green : .secondary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.fileName)
                        .font(.body)
                        .lineLimit(1)
                    HStack {
                        Text(model.formattedSize)
                        if let tier = model.matchedConfig?.tier {
                            Text("·")
                            Text(tier.label)
                                .foregroundColor(tier.color)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ModelImportView()
            .environment(AppState())
            .preferredColorScheme(.dark)
    }
}
