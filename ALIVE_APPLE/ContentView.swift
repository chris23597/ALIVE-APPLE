import SwiftUI

/// Root tab view for the app
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .onAppear {
            // Show onboarding if no models imported yet (first run)
            if appState.availableModels.isEmpty {
                showOnboarding = true
            }
        }
        .onChange(of: appState.availableModels.count) { _, count in
            if count > 0 {
                showOnboarding = false
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: Bindable(appState).selectedTab) {
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(AppState.Tab.chat)
            
            NavigationStack {
                VisionView()
            }
            .tabItem {
                Label("Vision", systemImage: "camera.fill")
            }
            .tag(AppState.Tab.vision)
            
            NavigationStack {
                ModelImportView()
            }
            .tabItem {
                Label("Models", systemImage: "square.and.arrow.down.fill")
            }
            .tag(AppState.Tab.models)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(AppState.Tab.settings)
        }
        .tint(appState.activeTier.color)
        .overlay(alignment: .top) {
            // Toast overlays
            if let error = appState.errorToast {
                ToastView(message: error, type: .error)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if let info = appState.infoToast {
                ToastView(message: info, type: .info)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.errorToast)
        .animation(.easeInOut(duration: 0.3), value: appState.infoToast)
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case error
        case info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Tier Badge

struct TierBadge: View {
    let tier: RoutingTier
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tier.color)
                .frame(width: 8, height: 8)
            Text(tier.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tier.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppState())
}
