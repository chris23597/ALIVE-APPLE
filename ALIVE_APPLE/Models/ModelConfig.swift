import Foundation

/// Configuration for a loaded model
struct ModelConfig: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let fileSizeBytes: Int64
    let parameterCount: String  // e.g., "3.8B", "7.6B"
    let quant: String           // "Q4_K_M"
    let modelType: ModelType
    let tier: RoutingTier
    let contextSize: Int
    let isLoaded: Bool
    let loadTimeSeconds: Double?
    
    enum ModelType: String, Codable {
        case text          // Pure text LLM
        case vision        // Vision-language model
        case embedding     // Text embeddings
        case speech        // Speech-to-text
    }
    
    var sizeGB: Double {
        Double(fileSizeBytes) / 1_000_000_000.0
    }
    
    var formattedSize: String {
        if sizeGB >= 1.0 {
            return String(format: "%.1f GB", sizeGB)
        } else {
            return String(format: "%.0f MB", sizeGB * 1000)
        }
    }
    
    var statusDescription: String {
        if isLoaded {
            return "Ready · \(formattedSize)"
        } else {
            return "Not Loaded · \(formattedSize)"
        }
    }
    
    // MARK: - Predefined Configurations
    
    static let phi4Mini = ModelConfig(
        id: "phi-4-mini-3.8b",
        name: "Phi-4 Mini 3.8B",
        fileName: "Phi-4-mini-instruct-Q4_K_M.gguf",
        fileSizeBytes: 2_400_000_000,
        parameterCount: "3.8B",
        quant: "Q4_K_M",
        modelType: .text,
        tier: .fast,
        contextSize: 4096,
        isLoaded: false,
        loadTimeSeconds: nil
    )
    
    static let qwen25_7b = ModelConfig(
        id: "qwen2.5-7b",
        name: "Qwen2.5 7B",
        fileName: "Qwen2.5-7B-Instruct-Q4_K_M.gguf",
        fileSizeBytes: 4_400_000_000,
        parameterCount: "7.6B",
        quant: "Q4_K_M",
        modelType: .text,
        tier: .moderate,
        contextSize: 8192,
        isLoaded: false,
        loadTimeSeconds: nil
    )
    
    static let smolVLM2 = ModelConfig(
        id: "smolvlm2-2.2b",
        name: "SmolVLM2 2.2B",
        fileName: "SmolVLM2-2.2B-Instruct-Q4_K_M.gguf",
        fileSizeBytes: 1_040_000_000,
        parameterCount: "2.2B",
        quant: "Q4_K_M",
        modelType: .vision,
        tier: .fast,
        contextSize: 4096,
        isLoaded: false,
        loadTimeSeconds: nil
    )
    
    static let qwen25VL_7b = ModelConfig(
        id: "qwen2.5-vl-7b",
        name: "Qwen2.5-VL 7B",
        fileName: "Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf",
        fileSizeBytes: 4_360_000_000,
        parameterCount: "7.6B",
        quant: "Q4_K_M",
        modelType: .vision,
        tier: .moderate,
        contextSize: 8192,
        isLoaded: false,
        loadTimeSeconds: nil
    )
    
    static let allModels: [ModelConfig] = [phi4Mini, qwen25_7b, smolVLM2, qwen25VL_7b]
}
