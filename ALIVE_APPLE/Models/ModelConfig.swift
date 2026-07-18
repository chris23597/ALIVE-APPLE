import Foundation

/// Model configurations for v1 Fast tier (iPhone 16 — small + strong).
/// Weights are **MLX safetensors** (typically 4-bit from mlx-community).
struct ModelConfig: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let directoryName: String      // Subdirectory under Documents/Models/
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
    
    /// HuggingFace repo ID for pre-quantized MLX weights (download / USB copy source).
    var hfRepoId: String {
        switch id {
        case "phi-4-mini-3.8b":
            // Primary chat model — strong ~3.8B instruct, 4-bit MLX for iPhone 16
            return "mlx-community/Phi-4-mini-instruct-4bit"
        case "smolvlm2-2.2b":
            return "mlx-community/SmolVLM2-2.2B-Instruct-4bit"
        default:
            return ""
        }
    }
    
    /// Short user-facing download hint
    var downloadHint: String {
        "HF: \(hfRepoId) → folder named `\(directoryName)` with .safetensors + config.json"
    }
    
    // MARK: - v1 Model Definitions (recommended for iPhone 16)
    
    /// Default text / reasoning model — Phi-4 Mini Instruct (4-bit MLX).
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
    
    /// Small vision model (optional) — keep for camera / photo analysis path.
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
    
    /// Default load order: text first, then vision.
    static let allModels: [ModelConfig] = [phi4Mini, smolVLM2]
    
    /// Recommended default for chat
    static let recommendedText: ModelConfig = .phi4Mini
}
