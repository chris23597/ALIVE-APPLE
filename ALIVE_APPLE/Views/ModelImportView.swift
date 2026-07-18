import SwiftUI

/// Model management and import view — v1 simplified.
/// Single model, USB import via document picker, model status display.
struct ModelImportView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services
    @State private var modelVM = ModelViewModel()
    @State private var selectedModels: Set<UUID> = []
    
    var body: some View {
        List {
            // MARK: - Current Status
            Section("Current Model") {
                HStack {
                    Circle()
                        .fill(services.isModelLoaded ? Color.green : Color.secondary)
                        .frame(width: 12, height: 12)
                    Text(services.loadedModel?.name ?? "No Model")
                        .font(.headline)
                    Spacer()
                    Text(modelVM.memoryUsageGB > 0
                         ? String(format: "%.1f GB used", modelVM.memoryUsageGB)
                         : "No model loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if modelVM.memoryUsageGB > 0 {
                    MemoryGaugeView(usedGB: modelVM.memoryUsageGB)
                        .frame(height: 40)
                }
            }
            
            // MARK: - Model Actions
            Section("Load Model") {
                Button(action: { Task { await modelVM.loadTextModel() } }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Load Phi-4 Mini 3.8B")
                                .font(.body)
                            Text("Text model · ~3GB · Fast responses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: { Task { await modelVM.loadVisionModel() } }) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Load SmolVLM2 2.2B")
                                .font(.body)
                            Text("Vision model · ~1.8GB · Image analysis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // MARK: - Model Import
            Section("Import Models") {
                Button(action: { modelVM.showDocumentPicker = true }) {
                    Label("Browse for Models", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Text("Select an MLX model directory containing .safetensors files and config.json from Files, iCloud, or a connected USB-C drive.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                // Scanning state
                if modelVM.isScanning {
                    HStack {
                        ProgressView().padding(.trailing, 8)
                        Text("Scanning...")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Discovered models
                if !modelVM.discoveredModels.isEmpty {
                    ForEach(modelVM.discoveredModels) { model in
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading) {
                                Text(model.fileName)
                                    .font(.subheadline)
                                Text(model.formattedSize)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let config = model.matchedConfig {
                                Text(config.name)
                                    .font(.caption)
                                    .foregroundColor(.green)
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
                
                // Import button
                if !modelVM.discoveredModels.isEmpty && !modelVM.isImporting {
                    Button(action: { Task { await modelVM.importAllDiscovered() } }) {
                        Label("Import \(modelVM.discoveredModels.count) model(s)", systemImage: "square.and.arrow.down.fill")
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
                    Text("No models imported yet. Use Browse to find MLX model directories.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(modelVM.availableModels) { model in
                        HStack {
                            Image(systemName: model.modelType == .text ? "brain.head.profile" : "eye.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .font(.subheadline)
                                Text("\(model.parameterCount) · \(model.quant) · \(model.formattedSize)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if model.isLoaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            
            // MARK: - Actions
            Section {
                Button(role: .destructive, action: { modelVM.unloadModel() }) {
                    Label("Unload Model", systemImage: "xmark.circle")
                }
                .disabled(!services.isModelLoaded)
            }
        }
        .navigationTitle("Models")
        .onAppear {
            modelVM.services = services
            Task { await modelVM.loadModelState() }
        }
        .sheet(isPresented: $modelVM.showDocumentPicker) {
            ModelDocumentPicker { urls in
                Task { await modelVM.scanPickedLocations(urls: urls) }
            }
        }
    }
}

// MARK: - Memory Gauge

struct MemoryGaugeView: View {
    let usedGB: Float
    private let totalGB: Float = 8.0
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usedGB / totalGB > 0.7 ? Color.red : Color.green)
                        .frame(width: geo.size.width * CGFloat(usedGB / totalGB), height: 8)
                        .animation(.easeInOut, value: usedGB)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(String(format: "%.1f GB", usedGB))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", totalGB)) GB total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
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
