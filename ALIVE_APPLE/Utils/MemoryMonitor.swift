import Foundation
import Observation

/// Monitors system memory pressure
/// Uses os_proc_available_memory() (iOS 13+) for system-level free memory,
/// not the app's own resident size from task_info.
@MainActor
@Observable
final class MemoryMonitor {
    
    var currentPressure: MemoryPressure = .normal
    var usedMemoryGB: Float = 0
    var freeMemoryGB: Float = 0
    var totalMemoryGB: Float = 8.0  // iPhone 16 default
    
    private var updateTimer: Timer?
    
    init() {
        updateMemoryInfo()
        startPeriodicUpdate()
    }
    
    private func startPeriodicUpdate() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryInfo()
            }
        }
    }
    
    private func updateMemoryInfo() {
        totalMemoryGB = Float(ProcessInfo.processInfo.physicalMemory) / 1_000_000_000.0
        
        // Use os_proc_available_memory() for system-level available memory (iOS 13+)
        // This reflects memory available to the whole system, not just our app.
        // Returns free memory in bytes, accounting for purgeable memory.
        let availableBytes = os_proc_available_memory()
        
        if availableBytes > 0 {
            freeMemoryGB = Float(availableBytes) / 1_000_000_000.0
            usedMemoryGB = max(0, totalMemoryGB - freeMemoryGB)
        } else {
            // Fallback: estimate from ProcessInfo.physicalMemory
            let physicalMemory = ProcessInfo.processInfo.physicalMemory
            let hostPort = mach_host_self()
            var hostSize = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
            var hostInfo = vm_statistics64_data_t()
            
            let result = withUnsafeMutablePointer(to: &hostInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
                    host_statistics64(hostPort, HOST_VM_INFO64, $0, &hostSize)
                }
            }
            
            if result == KERN_SUCCESS {
                let pageSize = UInt64(vm_kernel_page_size)  // nonisolated(unsafe) is OK here — read-only system value
                let freePages = hostInfo.free_count + hostInfo.inactive_count + hostInfo.purgeable_count
                freeMemoryGB = Float(UInt64(freePages) * pageSize) / 1_000_000_000.0
                usedMemoryGB = max(0, totalMemoryGB - freeMemoryGB)
            } else {
                // Last resort: rough estimate
                usedMemoryGB = Float(ProcessInfo.processInfo.physicalMemory) / 1_000_000_000.0 * 0.5
                freeMemoryGB = totalMemoryGB - usedMemoryGB
            }
        }
        
        // Determine pressure level based on percentage used
        let usagePercent = usedMemoryGB / totalMemoryGB
        if usagePercent > 0.85 {
            currentPressure = .critical
        } else if usagePercent > 0.75 {
            currentPressure = .warning
        } else if usagePercent > 0.5 {
            currentPressure = .normal
        } else {
            currentPressure = .low
        }
    }
    
    var pressureDescription: String {
        switch currentPressure {
        case .low:      return "Plenty free"
        case .normal:   return "Normal"
        case .warning:  return "Running low"
        case .critical: return "Critical — unload models"
        }
    }
    
    var pressureColor: String {
        switch currentPressure {
        case .low:      return "green"
        case .normal:   return "green"
        case .warning:  return "orange"
        case .critical: return "red"
        }
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
