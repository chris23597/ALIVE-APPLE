import SwiftUI

/// Vision analysis view — v1 simplified.
/// Single analysis path: capture/select image → VLM analysis → streaming result.
struct VisionView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services
    @State private var capturedImage: UIImage?
    @State private var selectedImage: UIImage?
    @State private var analysisPrompt: String = ""
    
    @State private var analysisResult: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    @State private var showCamera: Bool = false
    @State private var showPhotoPicker: Bool = false
    
    var displayImage: UIImage? {
        capturedImage ?? selectedImage
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image area
                if let image = displayImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    placeholderImage
                }
                
                captureButtons
                Divider()
                promptSection
                
                // Loading indicator
                if isLoading {
                    HStack(spacing: 12) {
                        ProgressView().scaleEffect(0.9)
                        Text("Analyzing image...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.green.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Result
                if !analysisResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Analysis")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        Text(LocalizedStringKey(analysisResult))
                            .font(.body)
                            .padding(12)
                            .background(Color.green.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if let error = errorMessage {
                    ErrorBanner(message: error)
                }
            }
            .padding(16)
        }
        .navigationTitle("Vision")
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
        .fullScreenCover(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .onChange(of: displayImage) { _, newImage in
            if newImage != nil {
                runAnalysis()
            } else {
                clearAll()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 250)
            
            VStack(spacing: 12) {
                Image(systemName: "camera.macro")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Capture or select an image\nto analyze")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var captureButtons: some View {
        HStack(spacing: 16) {
            Button(action: { showCamera = true }) {
                Label("Camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button(action: { showPhotoPicker = true }) {
                Label("Gallery", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if displayImage != nil {
                Button(role: .destructive, action: clearImage) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask about this image")
                .font(.headline)
            
            TextField(
                "E.g., 'What plant is this?' or 'Read this document'",
                text: $analysisPrompt,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .disabled(isLoading)
            .onSubmit { runAnalysis() }
        }
    }
    
    // MARK: - Actions
    
    private func runAnalysis() {
        guard let image = displayImage,
              let imageData = image.jpegData(compressionQuality: 0.85) else { return }
        
        isLoading = true
        errorMessage = nil
        analysisResult = ""
        
        let prompt = analysisPrompt.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Describe this image in detail. What do you see?"
            : analysisPrompt
        
        Task {
            do {
                // Ensure vision model is loaded
                _ = try await services.ensureVisionModelLoaded()
                
                let stream = await services.visionService.analyze(
                    imageData: imageData,
                    prompt: prompt,
                    engine: services.inferenceEngine
                )
                
                for try await token in stream {
                    analysisResult += token
                }
            } catch {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func clearImage() {
        capturedImage = nil
        selectedImage = nil
        clearAll()
    }
    
    private func clearAll() {
        analysisResult = ""
        errorMessage = nil
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        VisionView()
            .environment(AppState())
            .environment(ServiceContainer())
            .preferredColorScheme(.dark)
    }
}
