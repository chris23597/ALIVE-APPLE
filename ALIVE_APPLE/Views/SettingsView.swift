import SwiftUI
import UniformTypeIdentifiers

/// Settings view — API key, preferences, data management
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services
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
            
            // MARK: - RAG Documents
            Section {
                // Status row
                HStack {
                    VStack(alignment: .leading) {
                        Text("Local Documents")
                            .font(.body)
                        if settingsVM.ragSourceCount > 0 {
                            Text("\(settingsVM.ragSourceCount) document\(settingsVM.ragSourceCount == 1 ? "" : "s") · \(settingsVM.ragChunkCount) chunks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No documents indexed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: settingsVM.ragSourceCount > 0 ? "doc.text.fill" : "doc.text")
                            .foregroundColor(settingsVM.ragSourceCount > 0 ? .green : .secondary)
                        Text(settingsVM.ragBackend)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                // Embedding coverage bar
                if settingsVM.ragChunkCount > 0 && settingsVM.ragEmbeddingCoverage > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Semantic index: \(Int(settingsVM.ragEmbeddingCoverage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: settingsVM.ragEmbeddingCoverage)
                            .tint(settingsVM.ragEmbeddingCoverage >= 1.0 ? .green : .orange)
                    }
                }
                
                // Add document button
                Button {
                    settingsVM.showFileImporter = true
                } label: {
                    Label("Add Document", systemImage: "plus.doc")
                }
                .disabled(settingsVM.ragIsIndexing)
                
                if settingsVM.ragIsIndexing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Indexing document...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = settingsVM.ragError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Document list
                if !settingsVM.ragSources.isEmpty {
                    ForEach(settingsVM.ragSources, id: \.self) { source in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.secondary)
                            Text(source)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await settingsVM.removeDocument(sourceName: source) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    
                    Button(role: .destructive) {
                        settingsVM.showRemoveConfirm = true
                    } label: {
                        Label("Clear All Documents", systemImage: "trash")
                    }
                    .confirmationDialog(
                        "Clear all indexed documents?",
                        isPresented: $settingsVM.showRemoveConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Clear All", role: .destructive) {
                            Task { await settingsVM.clearAllDocuments() }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will remove all indexed document chunks. Imported files on disk are not deleted.")
                    }
                }
            } header: {
                Text("RAG — Local Documents")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Supports PDF, TXT, and Markdown files.")
                    if settingsVM.ragBackend == "hybrid" {
                        Text("Hybrid search: BM25 keyword + semantic embeddings from loaded model.")
                            .foregroundColor(.green)
                    } else {
                        Text("BM25 keyword search. Semantic search enabled when a model is loaded.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .fileImporter(
                isPresented: $settingsVM.showFileImporter,
                allowedContentTypes: [.pdf, .plainText, UTType(filenameExtension: "md") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task { await settingsVM.ingestDocument(url: url) }
                    }
                case .failure(let error):
                    settingsVM.ragError = error.localizedDescription
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
                LabeledContent("Engine", value: "llama.cpp + Hybrid RAG (BM25 + embeddings)")
                
                Link(destination: URL(string: "https://aliveapple.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            settingsVM.ragService = services.ragService
            Task { await settingsVM.loadSettings() }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState())
            .environment(ServiceContainer())
            .preferredColorScheme(.dark)
    }
}
