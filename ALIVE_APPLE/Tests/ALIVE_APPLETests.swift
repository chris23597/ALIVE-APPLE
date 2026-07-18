import XCTest
@testable import ALIVE_APPLE

/// Core unit tests for ALIVE APPLE v1.
/// These tests run without a device — no MLX Swift or Metal required.
final class ModelConfigTests: XCTestCase {
    
    // MARK: - Model Config Validation
    
    func testAllModelsHaveValidSizes() {
        for model in ModelConfig.allModels {
            XCTAssertGreaterThan(model.fileSizeBytes, 0, "\(model.name) should have positive file size")
            XCTAssertFalse(model.directoryName.isEmpty, "\(model.name) should have a directory name")
            XCTAssertGreaterThan(model.contextSize, 0, "\(model.name) should have positive context size")
        }
    }
    
    func testModelFormattedSize() {
        XCTAssertTrue(ModelConfig.phi4Mini.formattedSize.contains("GB"))
        XCTAssertTrue(ModelConfig.smolVLM2.formattedSize.contains("GB"))
    }
    
    func testModelTierMapping() {
        XCTAssertEqual(ModelConfig.phi4Mini.tier, .fast)
        XCTAssertEqual(ModelConfig.smolVLM2.tier, .fast)
    }
    
    func testModelTypeMapping() {
        XCTAssertEqual(ModelConfig.phi4Mini.modelType, .text)
        XCTAssertEqual(ModelConfig.smolVLM2.modelType, .vision)
    }
    
    func testV1OnlyHasTwoModels() {
        XCTAssertEqual(ModelConfig.allModels.count, 2)
    }
    
    func testHuggingFaceRepoIds() {
        XCTAssertEqual(ModelConfig.phi4Mini.hfRepoId, "mlx-community/Phi-4-mini-instruct-4bit")
        XCTAssertEqual(ModelConfig.smolVLM2.hfRepoId, "mlx-community/SmolVLM2-2.2B-Instruct-4bit")
    }
}

// MARK: - Routing Tier Tests (v1)

final class RoutingTierTests: XCTestCase {
    
    func testTextModelMapping() {
        XCTAssertEqual(RoutingTier.fast.textModel?.id, "phi-4-mini-3.8b")
        XCTAssertNil(RoutingTier.none.textModel)
    }
    
    func testVisionModelMapping() {
        XCTAssertEqual(RoutingTier.fast.visionModel?.id, "smolvlm2-2.2b")
        XCTAssertNil(RoutingTier.none.visionModel)
    }
    
    func testOnDeviceCheck() {
        XCTAssertTrue(RoutingTier.fast.isOnDevice)
    }
    
    func testNeverRequiresInternet() {
        XCTAssertFalse(RoutingTier.fast.requiresInternet)
        XCTAssertFalse(RoutingTier.none.requiresInternet)
    }
    
    func testV1OnlyHasTwoCases() {
        XCTAssertEqual(RoutingTier.allCases.count, 2)
        XCTAssertTrue(RoutingTier.allCases.contains(.fast))
        XCTAssertTrue(RoutingTier.allCases.contains(.none))
    }
}

// MARK: - InferenceError Tests

final class InferenceErrorTests: XCTestCase {
    
    func testModelFileNotFoundError() {
        let error = InferenceError.modelFileNotFound("phi-4-mini")
        XCTAssertTrue(error.errorDescription?.contains("phi-4-mini") ?? false)
    }
    
    func testModelLoadFailedError() {
        let error = InferenceError.modelLoadFailed("out of memory")
        XCTAssertTrue(error.errorDescription?.contains("out of memory") ?? false)
    }
    
    func testInferenceInProgressError() {
        let error = InferenceError.inferenceInProgress
        XCTAssertTrue(error.errorDescription?.contains("already generating") ?? false)
    }
    
    func testTimeoutError() {
        let error = InferenceError.timeout
        XCTAssertTrue(error.errorDescription?.contains("timed out") ?? false)
    }
}
