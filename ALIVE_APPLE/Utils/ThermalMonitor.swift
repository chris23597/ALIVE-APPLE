import Foundation
import Observation
import UIKit

/// Monitors device thermal state
@MainActor
@Observable
final class ThermalMonitor {
    
    var currentState: ThermalState = .nominal
    var isThrottling: Bool = false
    
    init() {
        updateState()
        startObserving()
    }
    
    private func startObserving() {
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateState()
        }
    }
    
    private func updateState() {
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            currentState = .nominal
            isThrottling = false
        case .fair:
            currentState = .fair
            isThrottling = false
        case .serious:
            currentState = .serious
            isThrottling = true
        case .critical:
            currentState = .critical
            isThrottling = true
        @unknown default:
            currentState = .nominal
        }
    }
    
    var description: String {
        switch currentState {
        case .nominal:  return "Cool"
        case .fair:     return "Warm"
        case .serious:  return "Hot — Fast tier only"
        case .critical: return "Very hot — pause inference"
        }
    }
    
    var systemImage: String {
        switch currentState {
        case .nominal:  return "thermometer.low"
        case .fair:     return "thermometer.medium"
        case .serious:  return "thermometer.high"
        case .critical: return "thermometer.snowflake"  // irony: too hot
        }
    }
}
