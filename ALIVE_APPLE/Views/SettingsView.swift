import SwiftUI

/// Settings view — API key, preferences, data management
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var settingsVM = SettingsViewModel()
    @State private var showClearConfirmation: Bool = false
    
    var body: some View {
        List {
            // MARK: - Pro Tier
            Section {
                if settingsVM.isKeyValid {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Grok API Key")
                                .font(.body)
                            Text(settingsVM.maskedKey)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button(role: .destructive) {
                        Task { await settingsVM.removeAPIKey() }
                    } label: {
                        Label("Remove API Key", systemImage: "trash")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Grok API Key")
                            .font(.headline)
                        
                        Text("Get your key at console.x.ai")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("xai-...", text: $settingsVM.apiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if settingsVM.isVerifying {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Verifying...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: {
                                Task { await settingsVM.saveAPIKey() }
                            }) {
                                Label("Save & Validate", systemImage: "key.fill")
                            }
                            .disabled(settingsVM.apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        
                        if let error = settingsVM.verificationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            } header: {
                Text("Pro Tier (Grok API)")
            } footer: {
                Text("Your API key is stored securely in the iOS Keychain and only sent to api.x.ai.")
            }
            
            // MARK: - Preferences
            Section("Preferences") {
                Toggle("Auto-play voice responses", isOn: $settingsVM.autoPlayVoice)
                    .onChange(of: settingsVM.autoPlayVoice) { _, newValue in
                        settingsVM.toggleAutoPlayVoice()
                    }
                
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
            
            // MARK: - Routing
            Section("Routing") {
                Picker("Default mode", selection: $settingsVM.routingMode) {
                    Text("Auto").tag(AppState.RoutingMode.auto)
                    Text("Manual").tag(AppState.RoutingMode.manual)
                }
                .pickerStyle(.segmented)
                .onChange(of: settingsVM.routingMode) { _, newValue in
                    appState.routingMode = newValue
                }
            }
            
            // MARK: - Data
            Section("Data") {
                Button(action: {
                    let json = settingsVM.exportChats()
                    // Share sheet in production
                }) {
                    Label("Export Chats (JSON)", systemImage: "square.and.arrow.up")
                }
                
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
                    Text("This will permanently delete all chat history. This action cannot be undone.")
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
                LabeledContent("Engine", value: "llama.cpp + BM25 RAG (no CoreML required)")
                
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
