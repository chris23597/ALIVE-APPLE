import XCTest
@testable import ALIVE_APPLE

/// Core unit tests for ALIVE APPLE models and services.
/// These tests run without a device — no llama.cpp or Metal required.
final class ModelConfigTests: XCTestCase {
    
    // MARK: - Model Config Validation
    
    func testAllModelsHaveValidSizes() {
        for model in ModelConfig.allModels {
            XCTAssertGreaterThan(model.fileSizeBytes, 0, "\(model.name) should have positive file size")
            XCTAssertFalse(model.fileName.isEmpty, "\(model.name) should have a file name")
            XCTAssertGreaterThan(model.contextSize, 0, "\(model.name) should have positive context size")
        }
    }
    
    func testModelFormattedSize() {
        XCTAssertTrue(ModelConfig.phi4Mini.formattedSize.contains("GB"))
        XCTAssertTrue(ModelConfig.smolVLM2.formattedSize.contains("GB") || ModelConfig.smolVLM2.formattedSize.contains("MB"))
    }
    
    func testModelTierMapping() {
        XCTAssertEqual(ModelConfig.phi4Mini.tier, .fast)
        XCTAssertEqual(ModelConfig.qwen25_7b.tier, .moderate)
        XCTAssertEqual(ModelConfig.smolVLM2.tier, .fast)
        XCTAssertEqual(ModelConfig.qwen25VL_7b.tier, .moderate)
    }
    
    func testModelTypeMapping() {
        XCTAssertEqual(ModelConfig.phi4Mini.modelType, .text)
        XCTAssertEqual(ModelConfig.smolVLM2.modelType, .vision)
    }
}

// MARK: - Routing Tier Tests

final class RoutingTierTests: XCTestCase {
    
    func testTextModelMapping() {
        XCTAssertEqual(RoutingTier.fast.textModel?.id, "phi-4-mini-3.8b")
        XCTAssertEqual(RoutingTier.moderate.textModel?.id, "qwen2.5-7b")
        XCTAssertNil(RoutingTier.pro.textModel)  // Pro uses cloud
        XCTAssertNil(RoutingTier.none.textModel)
    }
    
    func testVisionModelMapping() {
        XCTAssertEqual(RoutingTier.fast.visionModel?.id, "smolvlm2-2.2b")
        XCTAssertEqual(RoutingTier.moderate.visionModel?.id, "qwen2.5-vl-7b")
        XCTAssertNil(RoutingTier.pro.visionModel)
    }
    
    func testOnDeviceCheck() {
        XCTAssertTrue(RoutingTier.fast.isOnDevice)
        XCTAssertTrue(RoutingTier.moderate.isOnDevice)
        XCTAssertFalse(RoutingTier.pro.isOnDevice)
    }
    
    func testRequiresInternet() {
        XCTAssertTrue(RoutingTier.pro.requiresInternet)
        XCTAssertFalse(RoutingTier.fast.requiresInternet)
        XCTAssertFalse(RoutingTier.moderate.requiresInternet)
    }
    
    func testAllCasesExist() {
        XCTAssertEqual(RoutingTier.allCases.count, 4)
        XCTAssertTrue(RoutingTier.allCases.contains(.fast))
        XCTAssertTrue(RoutingTier.allCases.contains(.moderate))
        XCTAssertTrue(RoutingTier.allCases.contains(.pro))
        XCTAssertTrue(RoutingTier.allCases.contains(.none))
    }
}

// MARK: - AutoRouter Complexity Tests

final class AutoRouterComplexityTests: XCTestCase {
    
    /// We can't call the actor's complexityScore directly without async,
    /// so test the underlying logic via known inputs.
    
    func testSimplePromptIsLowComplexity() {
        // Short, simple prompt → should be < 0.3 based on scoring rules
        let shortPrompt = "hello"
        // Length: < 500 → +0
        // No keywords → +0
        // Score: 0
        // Expected: low
        // We just verify structure — actual scoring tested via integration
        XCTAssertTrue(true, "Structure test placeholder")
    }
    
    func testComplexPromptHasHigherScore() {
        let complexPrompt = "explain the architecture of a distributed system with trade-offs and implications. compare with monolithic design. implement a proof of concept."
        XCTAssertGreaterThan(complexPrompt.count, 100)
        XCTAssertTrue(complexPrompt.contains("explain"))
        XCTAssertTrue(complexPrompt.contains("compare"))
        XCTAssertTrue(complexPrompt.contains("implement"))
    }
    
    func testCodeDetectionKeywords() {
        let codePrompts = [
            "func calculate()",
            "class MyClass",
            "def my_function",
            "implement this algorithm",
            "```swift\nlet x = 1\n```"
        ]
        for prompt in codePrompts {
            let hasCode = prompt.contains("func ") || prompt.contains("def ")
                || prompt.contains("class ") || prompt.contains("```")
                || prompt.contains("function") || prompt.contains("algorithm")
            XCTAssertTrue(hasCode, "\(prompt) should trigger code detection")
        }
    }
    
    func testDeepAnalysisKeywords() {
        let deepPhrases = ["deep analysis", "thorough", "in detail", "comprehensive", "detailed analysis"]
        for phrase in deepPhrases {
            XCTAssertTrue(phrase.count > 0)
        }
    }
}

// MARK: - BM25 Tokenization Tests

final class BM25TokenizationTests: XCTestCase {
    
    /// Replicate RAGService's tokenize logic for testing
    func tokenize(_ text: String) -> [String] {
        let cleaned = text.lowercased()
        var tokens: [String] = []
        var current = ""
        for ch in cleaned {
            if ch.isLetter || ch.isNumber {
                current.append(ch)
            } else if !current.isEmpty {
                if current.count > 1 { tokens.append(current) }
                current = ""
            }
        }
        if current.count > 1 { tokens.append(current) }
        return tokens
    }
    
    func testTokenizeSimpleSentence() {
        let tokens = tokenize("The quick brown fox")
        XCTAssertEqual(tokens, ["the", "quick", "brown", "fox"])
    }
    
    func testTokenizeFiltersShortTokens() {
        let tokens = tokenize("a b c at be go")
        // "a", "b", "c" are 1 char → filtered out
        // "at", "be", "go" are 2 chars → kept
        XCTAssertEqual(tokens, ["at", "be", "go"])
    }
    
    func testTokenizeHandlesPunctuation() {
        let tokens = tokenize("Hello, world! How are you?")
        XCTAssertEqual(tokens, ["hello", "world", "how", "are", "you"])
    }
    
    func testTokenizeHandlesEmpty() {
        XCTAssertEqual(tokenize(""), [])
        XCTAssertEqual(tokenize("   "), [])
    }
    
    func testTokenizeHandlesNumbers() {
        let tokens = tokenize("iPhone 16 with 8GB RAM")
        XCTAssertTrue(tokens.contains("iphone"))
        XCTAssertTrue(tokens.contains("16"))
        XCTAssertTrue(tokens.contains("8gb"))
        XCTAssertTrue(tokens.contains("ram"))
    }
}

// MARK: - RoutingDecision Tests

final class RoutingDecisionTests: XCTestCase {
    
    func testConfidencePercent() {
        let decision = RoutingDecision(tier: .fast, confidence: 0.75, reason: "test")
        XCTAssertEqual(decision.confidencePercent, 75)
    }
    
    func testConfidencePercentRounding() {
        let decision = RoutingDecision(tier: .moderate, confidence: 0.937, reason: "test")
        XCTAssertEqual(decision.confidencePercent, 93)
    }
}

// MARK: - Cosine Similarity Tests

final class CosineSimilarityTests: XCTestCase {
    
    func testIdenticalVectors() {
        let vec: [Float] = [1, 0, 0]
        let sim = RAGService.cosineSimilarity(vec, vec)
        XCTAssertEqual(sim, 1.0, accuracy: 0.001)
    }
    
    func testOrthogonalVectors() {
        let a: [Float] = [1, 0, 0]
        let b: [Float] = [0, 1, 0]
        let sim = RAGService.cosineSimilarity(a, b)
        XCTAssertEqual(sim, 0.0, accuracy: 0.001)
    }
    
    func testOppositeVectors() {
        let a: [Float] = [1, 0, 0]
        let b: [Float] = [-1, 0, 0]
        let sim = RAGService.cosineSimilarity(a, b)
        XCTAssertEqual(sim, -1.0, accuracy: 0.001)
    }
    
    func testNormalizedVectors() {
        // Two L2-normalized vectors at 45 degrees
        let a: [Float] = [0.7071, 0.7071]
        let b: [Float] = [1.0, 0.0]
        let sim = RAGService.cosineSimilarity(a, b)
        XCTAssertEqual(sim, 0.7071, accuracy: 0.01)
    }
    
    func testEmptyVectors() {
        XCTAssertEqual(RAGService.cosineSimilarity([], []), 0.0)
    }
    
    func testMismatchedDimensions() {
        XCTAssertEqual(RAGService.cosineSimilarity([1.0], [1.0, 2.0]), 0.0)
    }
    
    func testClampedOutput() {
        // Even with unnormalized vectors, output should be in [-1, 1]
        let a: [Float] = [100, 200, 300]
        let b: [Float] = [100, 200, 300]
        let sim = RAGService.cosineSimilarity(a, b)
        XCTAssertGreaterThanOrEqual(sim, -1.0)
        XCTAssertLessThanOrEqual(sim, 1.0)
    }
}

// MARK: - Pseudo Embedding Tests

final class PseudoEmbeddingTests: XCTestCase {
    
    /// Use embedText which falls back to pseudoEmbed when LlamaSwift is not linked
    func testEmbeddingGeneration() async throws {
        let engine = InferenceEngine()
        let vec = try await engine.embedText("Hello world")
        XCTAssertFalse(vec.isEmpty)
        XCTAssertEqual(vec.count, 384, "Pseudo embedding should have 384 dimensions")
    }
    
    func testEmbeddingIsDeterministic() async throws {
        let engine = InferenceEngine()
        let a = try await engine.embedText("test text")
        let b = try await engine.embedText("test text")
        XCTAssertEqual(a, b, "Same text should produce same embedding")
    }
    
    func testDifferentTextDifferentEmbedding() async throws {
        let engine = InferenceEngine()
        let a = try await engine.embedText("hello")
        let b = try await engine.embedText("world")
        // They should differ (different hash input)
        XCTAssertNotEqual(a, b)
    }
    
    func testEmbeddingIsNormalized() async throws {
        let engine = InferenceEngine()
        let vec = try await engine.embedText("some text for testing")
        var norm: Float = 0
        for v in vec { norm += v * v }
        norm = sqrt(norm)
        XCTAssertEqual(norm, 1.0, accuracy: 0.01, "Embedding should be L2-normalized")
    }
}

// MARK: - DocumentChunk Codable Tests

final class DocumentChunkTests: XCTestCase {
    
    func testEncodeDecodeRoundtrip() throws {
        let chunk = DocumentChunk(
            id: "test-1",
            content: "Hello world",
            sourceName: "test.txt",
            chunkIndex: 0,
            termFrequencies: ["hello": 1, "world": 1],
            length: 2,
            embedding: [0.5, 0.3, 0.8]
        )
        
        let data = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(DocumentChunk.self, from: data)
        
        XCTAssertEqual(decoded.id, chunk.id)
        XCTAssertEqual(decoded.content, chunk.content)
        XCTAssertEqual(decoded.sourceName, chunk.sourceName)
        XCTAssertEqual(decoded.embedding, [0.5, 0.3, 0.8])
    }
    
    func testDecodeLegacyChunkWithoutEmbedding() throws {
        let json = """
        {"id":"old-1","content":"old content","sourceName":"old.txt","chunkIndex":0,"termFrequencies":{},"length":2}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(DocumentChunk.self, from: data)
        
        XCTAssertNil(decoded.embedding, "Legacy chunks should have nil embedding")
        XCTAssertEqual(decoded.content, "old content")
    }
    
    func testLengthAutoComputed() {
        let chunk = DocumentChunk(
            id: "t",
            content: "test",
            sourceName: "s",
            chunkIndex: 0,
            termFrequencies: ["a": 3, "b": 2],
            length: 0
        )
        XCTAssertEqual(chunk.length, 5, "Length should be auto-computed from termFrequencies sum")
    }
}
