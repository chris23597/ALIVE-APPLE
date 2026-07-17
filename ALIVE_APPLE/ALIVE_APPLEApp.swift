import SwiftUI
import SwiftData

/// App entry point — sets up SwiftData, global state, and shared services
@main
struct ALIVE_APPLEApp: App {
    
    @State private var appState = AppState()
    @State private var thermalMonitor = ThermalMonitor()
    @State private var memoryMonitor = MemoryMonitor()
    @State private var services = ServiceContainer()
    @Environment(\.scenePhase) private var scenePhase
    
    /// Track the sync task so we can cancel it when the app backgrounds
    @State private var syncTask: Task<Void, Never>?
    
    var modelContainer: ModelContainer {
        do {
            return try ModelContainer(for: ChatMessage.self, Conversation.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(thermalMonitor)
                .environment(memoryMonitor)
                .environment(services)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                startMonitorSync()
            case .inactive, .background:
                stopMonitorSync()
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Monitor Syncing
    
    /// Start periodically syncing thermal/memory/battery state to AppState.
    /// Runs only when the app is active; pauses when backgrounded.
    private func startMonitorSync() {
        stopMonitorSync()
        
        syncTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    appState.thermalState = thermalMonitor.currentState
                    appState.memoryPressure = memoryMonitor.currentPressure
                    appState.batteryLevel = Float(UIDevice.current.batteryLevel)
                }
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    break
                }
            }
        }
    }
    
    private func stopMonitorSync() {
        syncTask?.cancel()
        syncTask = nil
    }
}
