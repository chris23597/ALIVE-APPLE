import Foundation

/// Model configurations for v1 Fast tier only.
/// Both models use MLX format (safetensors, 4-bit quantized).
struct ModelConfig: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let directoryName: String      // Subdirectory in Models/ containing safetensors
    let fileSizeBytes: Int64
    let parameterCount: String
    let quant: String
    let modelType: ModelType
    let tier: RoutingTier
    let contextSize: Int
    let isLoaded: Bool
    
    enum ModelType: String, Codable {
        case text
        case vision
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
        isLoaded ? "Ready · \(formattedSize)" : "Not Loaded · \(formattedSize)"
    }
    
    /// HuggingFace repo ID for mlx-community pre-quantized model
    var hfRepoId: String {
        switch id {
        case "phi-4-mini-3.8b": return "mlx-community/Phi-4-mini-instruct-4bit"
        case "smolvlm2-2.2b":   return "mlx-community/SmolVLM2-2.2B-Instruct-4bit"
        default:                return ""
        }
    }
    
    // MARK: - v1 Model Definitions
    
    static let phi4Mini = ModelConfig(
        id: "phi-4-mini-3.8b",
        name: "Phi-4 Mini 3.8B",
        directoryName: "phi-4-mini",
        fileSizeBytes: 2_400_000_000,
        parameterCount: "3.8B",
        quant: "4-bit MLX",
        modelType: .text,
        tier: .fast,
        contextSize: 4096,
        isLoaded: false
    )
    
    static let smolVLM2 = ModelConfig(
        id: "smolvlm2-2.2b",
        name: "SmolVLM2 2.2B",
        directoryName: "smolvlm2",
        fileSizeBytes: 1_200_000_000,
        parameterCount: "2.2B",
        quant: "4-bit MLX",
        modelType: .vision,
        tier: .fast,
        contextSize: 2048,
        isLoaded: false
    )
    
    static let allModels: [ModelConfig] = [phi4Mini, smolVLM2]
}
