import SwiftUI

/// Settings view — v1 simplified.
/// No API key, no RAG, no routing. Just preferences + data management.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var settingsVM = SettingsViewModel()
    @State private var showClearConfirmation: Bool = false
    
    var body: some View {
        List {
            // MARK: - Preferences
            Section("Preferences") {
                Toggle("Haptic feedback", isOn: $settingsVM.hapticFeedback)
                    .onChange(of: settingsVM.hapticFeedback) { _, newValue in
                        settingsVM.toggleHapticFeedback()
                    }
                
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(String(format: "%.1f", settingsVM.defaultTemperature))
                        .foregroundColor(.secondary)
                    Slider(value: $settingsVM.defaultTemperature, in: 0.1...2.0, step: 0.1)
                        .frame(width: 100)
                }
                
                Stepper("Max tokens: \(settingsVM.maxTokens)",
                        value: $settingsVM.maxTokens,
                        in: 256...8192,
                        step: 256)
            }
            
            // MARK: - Model Status
            Section("Model") {
                HStack {
                    Text("Loaded Model")
                    Spacer()
                    if let model = appState.loadedModel {
                        Text("\(model.name) (\(model.formattedSize))")
                            .foregroundColor(.green)
                    } else {
                        Text("None")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Memory")
                    Spacer()
                    Text(appState.memoryDescription)
                        .foregroundColor(
                            appState.memoryPressure == .critical ? .red :
                            appState.memoryPressure == .warning ? .orange : .secondary
                        )
                }
                
                HStack {
                    Text("Thermal")
                    Spacer()
                    Text(appState.thermalDescription)
                        .foregroundColor(
                            appState.thermalState == .critical ? .red :
                            appState.thermalState == .serious ? .orange : .secondary
                        )
                }
            }
            
            // MARK: - Data
            Section("Data") {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear All Chats", systemImage: "trash")
                }
                .confirmationDialog(
                    "Clear all chats?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) {
                        settingsVM.clearAllChats()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all chat history.")
                }
                
                Button {
                    settingsVM.clearModelCache()
                } label: {
                    Label("Clear Model Cache", systemImage: "square.stack.3d.up.slash")
                }
            }
            
            // MARK: - About
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Target", value: "iPhone 16 (A18, 8GB)")
                LabeledContent("Backend", value: "MLX Swift")
                LabeledContent("Models", value: "Phi-4 Mini 3.8B + SmolVLM2 2.2B")
                LabeledContent("Status", value: "Fully Offline · No Cloud")
                
                Link(destination: URL(string: "https://aliveapple.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            Task { await settingsVM.loadSettings() }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState())
            .preferredColorScheme(.dark)
    }
}
