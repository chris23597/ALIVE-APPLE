import SwiftUI

/// First-run onboarding wizard — guides user through USB model import
/// Shown automatically when no models are detected on fresh launch
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var isScanning: Bool = false
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case formatUSB = 1
        case downloadModels = 2
        case importModels = 3
        case ready = 4
        
        var title: String {
            switch self {
            case .welcome:        return "Welcome to ALIVE APPLE"
            case .formatUSB:      return "Step 1: Format Your USB Drive"
            case .downloadModels: return "Step 2: Download Models"
            case .importModels:   return "Step 3: Import to iPhone"
            case .ready:          return "You're Ready!"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue
                              ? Color.green
                              : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 16)
            
            TabView(selection: $currentStep) {
                welcomePage.tag(OnboardingStep.welcome)
                formatUSBPage.tag(OnboardingStep.formatUSB)
                downloadModelsPage.tag(OnboardingStep.downloadModels)
                importModelsPage.tag(OnboardingStep.importModels)
                readyPage.tag(OnboardingStep.ready)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color.black.opacity(0.95))
    }
    
    // MARK: - Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
            }
            
            Text("ALIVE APPLE")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("Your on-device AI agent for iPhone 16")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("All processing stays on your device.\nNo cloud required. No data leaves.")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Quick start button
            VStack(spacing: 12) {
                ActionButton(
                    title: "Let's Set Up Models",
                    systemImage: "arrow.right",
                    color: .green
                ) {
                    withAnimation { currentStep = .formatUSB }
                }
                
                Button("I already have models — skip setup") {
                    appState.selectedTab = .models
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .padding(32)
    }
    
    // MARK: - Format USB
    
    private var formatUSBPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "externaldrive.fill.badge.minus")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Format Your USB Drive")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "1.circle.fill",
                    text: "Insert a 256GB USB-C drive into your Mac"
                )
                InfoRow(
                    icon: "2.circle.fill",
                    text: "Open Disk Utility → Erase → exFAT format"
                )
                InfoRow(
                    icon: "3.circle.fill",
                    text: "Label it \"ALIVE_MODELS\""
                )
            }
            .padding(.horizontal, 16)
            
            Text("exFAT is required for large model files (>4GB).\niOS reads exFAT natively via the Files app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation { currentStep = .welcome }
                }
                .buttonStyle(.bordered)
                
                ActionButton(
                    title: "Done — Next Step",
                    systemImage: "arrow.right",
                    color: .blue
                ) {
                    withAnimation { currentStep = .downloadModels }
                }
            }
            .padding(.bottom, 40)
        }
        .padding(32)
    }
    
    // MARK: - Download Models
    
    private var downloadModelsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Download Models")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "1.circle.fill",
                    text: "On your Mac, run: bash Scripts/download_models.sh"
                )
                InfoRow(
                    icon: "2.circle.fill",
                    text: "Downloads 4 models (~13 GB total) to USB drive"
                )
                InfoRow(
                    icon: "3.circle.fill",
                    text: "Models include: Phi-4 Mini, Qwen2.5 7B, SmolVLM2, Qwen2.5-VL"
                )
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                ModelBadge(name: "Phi-4 Mini 3.8B", tier: .fast, size: "2.4 GB")
                ModelBadge(name: "Qwen2.5 7B", tier: .moderate, size: "4.4 GB")
                ModelBadge(name: "SmolVLM2 2.2B", tier: .fast, size: "1.4 GB")
                ModelBadge(name: "Qwen2.5-VL 7B", tier: .moderate, size: "4.7 GB")
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation { currentStep = .formatUSB }
                }
                .buttonStyle(.bordered)
                
                ActionButton(
                    title: "Done — Next Step",
                    systemImage: "arrow.right",
                    color: .blue
                ) {
                    withAnimation { currentStep = .importModels }
                }
            }
            .padding(.bottom, 40)
        }
        .padding(32)
    }
    
    // MARK: - Import Models
    
    private var importModelsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Import to iPhone")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "1.circle.fill",
                    text: "Plug USB drive into your iPhone 16"
                )
                InfoRow(
                    icon: "2.circle.fill",
                    text: "Open ALIVE APPLE → Models tab"
                )
                InfoRow(
                    icon: "3.circle.fill",
                    text: "Tap 'Scan for Models' → select all → 'Import'"
                )
                InfoRow(
                    icon: "4.circle.fill",
                    text: "Fast tier loads automatically (~3.8 GB)"
                )
            }
            .padding(.horizontal, 16)
            
            // Scan button
            if isScanning {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking for USB models...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: skipToReady) {
                    Label("I'll do this now — scan available", systemImage: "magnifyingglass")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation { currentStep = .downloadModels }
                }
                .buttonStyle(.bordered)
                
                ActionButton(
                    title: "Skip to Chat",
                    systemImage: "message.fill",
                    color: .green
                ) {
                    skipToReady()
                }
            }
            .padding(.bottom, 40)
        }
        .padding(32)
    }
    
    // MARK: - Ready
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
            }
            
            Text("You're Ready!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("Once models are imported, you can:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    BulletPoint(text: "Chat with on-device AI — fully offline")
                    BulletPoint(text: "Analyze photos with Vision mode")
                    BulletPoint(text: "Use voice input & output")
                    BulletPoint(text: "Switch between Fast / Moderate tiers")
                    BulletPoint(text: "Add Grok API key for Pro tier")
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            ActionButton(
                title: "Get Started!",
                systemImage: "hand.wave.fill",
                color: .green
            ) {
                appState.selectedTab = .chat
            }
            .padding(.bottom, 40)
        }
        .padding(32)
    }
}

// MARK: - Helper Subviews

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct ModelBadge: View {
    let name: String
    let tier: RoutingTier
    let size: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(tier.color)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(size)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(tier.label)
                .font(.caption2)
                .foregroundColor(tier.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tier.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
