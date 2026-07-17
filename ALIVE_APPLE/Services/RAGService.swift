import Foundation

/// Local RAG (Retrieval-Augmented Generation) service
/// Indexes documents and retrieves relevant context for prompts
actor RAGService {
    
    // MARK: - Configuration
    
    private let maxChunkSize = 512
    private let chunkOverlap = 50
    private let topK = 3
    
    // MARK: - Document Storage
    
    private var documentChunks: [DocumentChunk] = []
    private var embeddings: [String: [Float]] = [:]  // chunkID → embedding
    
    private var documentsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("RAG", isDirectory: true)
    }
    
    // MARK: - Document Ingestion
    
    /// Ingest a document file (PDF, TXT, MD)
    func ingestDocument(url: URL) async throws -> Int {
        let text = try extractText(from: url)
        let chunks = chunkText(text)
        
        for chunk in chunks {
            documentChunks.append(chunk)
            
            // Generate embedding (placeholder — real impl uses CoreML all-MiniLM-L6-v2)
            let embedding = generateEmbedding(for: chunk.content)
            embeddings[chunk.id] = embedding
        }
        
        // Persist chunks
        try await saveChunks()
        
        return chunks.count
    }
    
    /// Search for relevant chunks given a query
    func search(query: String, topK: Int = 3) async -> [DocumentChunk] {
        guard !documentChunks.isEmpty else { return [] }
        
        let queryEmbedding = generateEmbedding(for: query)
        
        // Compute cosine similarity with all chunks
        var scored: [(DocumentChunk, Float)] = []
        for chunk in documentChunks {
            if let chunkEmbedding = embeddings[chunk.id] {
                let similarity = cosineSimilarity(queryEmbedding, chunkEmbedding)
                scored.append((chunk, similarity))
            }
        }
        
        // Sort by similarity (descending) and take topK
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(topK).map { $0.0 })
    }
    
    /// Build RAG-augmented prompt
    func augmentPrompt(userPrompt: String) async -> String {
        let relevantChunks = await search(query: userPrompt, topK: topK)
        
        guard !relevantChunks.isEmpty else {
            return userPrompt
        }
        
        var context = "Relevant context from your documents:\n\n"
        for (i, chunk) in relevantChunks.enumerated() {
            context += "--- Document: \(chunk.sourceName) ---\n"
            context += chunk.content + "\n\n"
        }
        
        context += "Based on the above context, please answer:\n\(userPrompt)"
        
        return context
    }
    
    // MARK: - Text Extraction
    
    private func extractText(from url: URL) throws -> String {
        switch url.pathExtension.lowercased() {
        case "txt", "md":
            return try String(contentsOf: url, encoding: .utf8)
        case "pdf":
            // In production: use PDFKit or Vision
            return try extractPDFText(url: url)
        default:
            throw RAGError.unsupportedFormat(url.pathExtension)
        }
    }
    
    private func extractPDFText(url: URL) throws -> String {
        // PDFKit-based extraction (placeholder)
        // In production: use PDFKit.PDFDocument
        return "PDF text extraction placeholder for: \(url.lastPathComponent)"
    }
    
    // MARK: - Text Chunking
    
    private func chunkText(_ text: String) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        let words = text.split(separator: " ")
        var index = 0
        
        while index < words.count {
            let end = min(index + maxChunkSize, words.count)
            let chunkWords = words[index..<end]
            let content = chunkWords.joined(separator: " ")
            
            let chunk = DocumentChunk(
                id: UUID().uuidString,
                content: content,
                sourceName: "document",
                chunkIndex: chunks.count
            )
            chunks.append(chunk)
            
            index += maxChunkSize - chunkOverlap
        }
        
        return chunks
    }
    
    // MARK: - Embeddings
    
    private func generateEmbedding(for text: String) -> [Float] {
        // Placeholder — real implementation uses CoreML all-MiniLM-L6-v2
        // Returns a 384-dimensional embedding
        //
        // Production code:
        // 1. Tokenize text with MiniLM tokenizer
        // 2. Run CoreML inference
        // 3. Return embedding vector
        
        // Deterministic pseudo-embedding based on text hash
        var embedding = [Float](repeating: 0, count: 384)
        let hash = text.hashValue
        var seed = hash
        for i in 0..<384 {
            seed = seed &* 1103515245 &+ 12345
            embedding[i] = Float((seed >> 16) & 0x7FFF) / Float(0x7FFF) * 2 - 1
        }
        
        // Normalize
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }
        
        return embedding
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
    
    // MARK: - Persistence
    
    private func saveChunks() async throws {
        try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        
        let chunksURL = documentsDirectory.appendingPathComponent("chunks.json")
        let data = try JSONEncoder().encode(documentChunks)
        try data.write(to: chunksURL)
    }
    
    func loadChunks() async throws {
        let chunksURL = documentsDirectory.appendingPathComponent("chunks.json")
        guard FileManager.default.fileExists(atPath: chunksURL.path) else { return }
        
        let data = try Data(contentsOf: chunksURL)
        documentChunks = try JSONDecoder().decode([DocumentChunk].self, from: data)
        
        // Rebuild embeddings
        for chunk in documentChunks {
            embeddings[chunk.id] = generateEmbedding(for: chunk.content)
        }
    }
    
    // MARK: - Management
    
    func documentCount() -> Int {
        documentChunks.count
    }
    
    func clearAll() {
        documentChunks.removeAll()
        embeddings.removeAll()
    }
}

// MARK: - Supporting Types

struct DocumentChunk: Codable, Identifiable {
    let id: String
    let content: String
    let sourceName: String
    let chunkIndex: Int
}

enum RAGError: LocalizedError {
    case unsupportedFormat(String)
    case embedFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported file format: .\(ext)"
        case .embedFailed:
            return "Embedding generation failed"
        }
    }
}
