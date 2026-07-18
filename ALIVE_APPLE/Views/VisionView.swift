import SwiftUI

/// Vision analysis view — camera capture, photo picker, VLM analysis with Smoke→Deep UX
///
/// UX Pattern (from competitive-edge / alive-smoke-deep):
/// 1. **Smoke (fast):** 1–3 lines + safety + best guess common name
/// 2. **CTA:** "Tap Deep Analysis for full profile / manuals"
/// 3. **Deep (slow):** more detail, citations — **timeout capped at 45s**
/// 4. Never leave user on spinner with no interim text
struct VisionView: View {
    @Environment(AppState.self) private var appState
    @State private var capturedImage: UIImage?
    @State private var selectedImage: UIImage?
    @State private var analysisPrompt: String = ""
    
    // Smoke state
    @State private var smokeResult: String = ""
    @State private var isSmokeLoading: Bool = false
    @State private var smokeTier: RoutingTier = .fast
    
    // Deep state
    @State private var deepResult: String = ""
    @State private var isDeepLoading: Bool = false
    @State private var deepProgress: String = "Starting deep analysis..."
    @State private var showDeep: Bool = false
    
    // Error
    @State private var errorMessage: String?
    
    // Capture
    @State private var showCamera: Bool = false
    @State private var showPhotoPicker: Bool = false
    
    private let visionService = VisionService()
    
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
                
                // Capture + clear buttons
                captureButtons
                
                Divider()
                
                // Prompt input
                promptSection
                
                // ⚡ SMOKE RESULT (fast — always shown first)
                if isSmokeLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.9)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick analysis...")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Text("Fast VLM scanning the image")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.green.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if !smokeResult.isEmpty {
                    smokeResultCard
                }
                
                // 🔍 DEEP ANALYSIS (optional — user taps CTA)
                if showDeep && isDeepLoading {
                    deepLoadingCard
                }
                
                if !deepResult.isEmpty {
                    deepResultCard
                }
                
                // CTA button
                if !smokeResult.isEmpty && !showDeep {
                    deepAnalysisCTA
                }
                
                // Error
                if let error = errorMessage {
                    ErrorBanner(message: error)
                }
            }
            .padding(16)
        }
        .navigationTitle("Vision")
        .animation(.easeInOut(duration: 0.3), value: smokeResult)
        .animation(.easeInOut(duration: 0.3), value: showDeep)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
        .fullScreenCover(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .onChange(of: displayImage) { _, newImage in
            if newImage != nil {
                // Auto-trigger smoke when image is selected
                runSmokeAnalysis()
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
            .disabled(isSmokeLoading || isDeepLoading)
            .onSubmit { runSmokeAnalysis() }
        }
    }
    
    private var smokeResultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Quick Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                Spacer()
                TierBadge(tier: smokeTier)
            }
            
            Text(LocalizedStringKey(smokeResult))
                .font(.body)
                .padding(12)
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if !isSmokeLoading {
                Text("⚡ Fast VLM — ready in ~2-4s")
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
            }
        }
    }
    
    private var deepAnalysisCTA: some View {
        Button(action: runDeepAnalysis) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tap for Deep Analysis")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("Detailed identification, references, citations (up to 45s)")
                        .font(.caption2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var deepLoadingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Deep Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            HStack {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 8, height: 8)
                Text(deepProgress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Linear progress indicator
            ProgressView(value: 0.0, total: 45.0)
                .tint(.orange)
            
            Text("⏱ Timeout at 45s · using \(smokeTier == .fast ? "Moderate" : "Fast") VLM")
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .padding(12)
        .background(Color.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var deepResultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Deep Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if deepResult.count > 100 {
                    Text("\(deepResult.count) chars")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(LocalizedStringKey(deepResult))
                .font(.body)
                .padding(12)
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    /// Phase 1: Fast smoke analysis — always runs first when image appears
    private func runSmokeAnalysis() {
        guard let image = displayImage,
              let imageData = image.jpegData(compressionQuality: 0.85) else { return }
        
        isSmokeLoading = true
        errorMessage = nil
        smokeResult = ""
        showDeep = false
        deepResult = ""
        
        // Use prompt if user typed something, else default
        let prompt = analysisPrompt.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Briefly describe this image. What's the most notable thing? Give a 1-3 line summary only."
            : "Quick summary (1-3 lines): \(analysisPrompt)"
        
        Task {
            do {
                let engine = InferenceEngine()
                let manager = ModelManager(engine: engine)
                
                // Fast tier is always available — this is the smoke path
                let result = try await visionService.analyze(
                    imageData: imageData,
                    prompt: prompt,
                    tier: .fast,
                    engine: engine,
                    modelManager: manager
                )
                
                smokeResult = result
                smokeTier = .fast
            } catch {
                errorMessage = "Quick analysis failed: \(error.localizedDescription)"
                smokeResult = "Analysis unavailable. Try a different image or check model status."
            }
            
            isSmokeLoading = false
        }
    }
    
    /// Phase 2: Deep analysis — user-initiated, timed, more thorough
    private func runDeepAnalysis() {
        guard let image = displayImage,
              let imageData = image.jpegData(compressionQuality: 0.85) else { return }
        
        showDeep = true
        isDeepLoading = true
        deepResult = ""
        deepProgress = "Loading stronger model..."
        
        let prompt = analysisPrompt.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Describe this image in detail. Identify any objects, text, plants, or notable features. Provide thorough analysis with specific observations."
            : "Provide a thorough detailed analysis of this image: \(analysisPrompt)"
        
        Task {
            do {
                let engine = InferenceEngine()
                let manager = ModelManager(engine: engine)
                
                // Try moderate tier; fall back to fast if unavailable
                let tier: RoutingTier = appState.availableModels.contains(where: { $0.tier == .moderate && $0.modelType == .vision })
                    ? .moderate
                    : .fast
                
                deepProgress = "Analyzing in depth (\(tier.rawValue) tier)..."
                
                // Hard timeout: 45 seconds
                let timedResult = try await withThrowingTaskGroup(of: String.self) { group in
                    group.addTask {
                        try await visionService.analyze(
                            imageData: imageData,
                            prompt: prompt,
                            tier: tier,
                            engine: engine,
                            modelManager: manager
                        )
                    }
                    group.addTask {
                        // Timeout
                        try await Task.sleep(for: .seconds(45))
                        throw DeepAnalysisError.timeout
                    }
                    
                    let result = try await group.next()!
                    group.cancelAll()
                    return result
                }
                
                deepResult = timedResult
            } catch DeepAnalysisError.timeout {
                deepResult = """
                ⏱ **Analysis timed out after 45s**
                
                The full analysis required more time. Here's what we found so far:
                
                \(smokeResult)
                
                **Tips:**
                - Try a smaller or clearer image
                - Switch to Pro tier for faster cloud analysis
                """
            } catch {
                deepResult = """
                🔄 **Deep analysis error:** \(error.localizedDescription)
                
                **Quick analysis result** (already available above) covers the main identification.
                """
            }
            
            isDeepLoading = false
            deepProgress = "Complete"
        }
    }
    
    private func clearImage() {
        capturedImage = nil
        selectedImage = nil
    }
    
    private func clearAll() {
        smokeResult = ""
        deepResult = ""
        errorMessage = nil
        showDeep = false
        isSmokeLoading = false
        isDeepLoading = false
    }
}

// MARK: - Deep Analysis Error

enum DeepAnalysisError: LocalizedError {
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .timeout: return "Deep analysis took too long (>45s)"
        }
    }
}

#Preview {
    NavigationStack {
        VisionView()
            .environment(AppState())
            .preferredColorScheme(.dark)
    }
}
