import Foundation
import PDFKit

/// Local RAG (Retrieval-Augmented Generation) — **no Mac / no CoreML required**.
///
/// Dual retrieval: **BM25 keyword** (always available) + **on-device embeddings**
/// via the loaded llama.cpp model. When an embedding provider is wired, hybrid
/// search fuses BM25 + cosine similarity scores for best results.
///
/// No `EmbeddingModel.mlmodelc` needed — the same GGUF model used for chat
/// generates embeddings via `llama_get_embeddings()`.
actor RAGService {
    
    // MARK: - Configuration
    
    private let maxChunkSize = 512       // words per chunk
    private let chunkOverlap = 50
    private let topK = 3
    
    // BM25 hyperparameters (classic defaults)
    private let k1: Double = 1.2
    private let b: Double = 0.75
    
    // Hybrid search weights (alpha=1.0 = BM25 only, alpha=0.0 = vector only)
    private let hybridAlpha: Double = 0.6   // 60% BM25, 40% vector
    
    // MARK: - Document Storage
    
    private var documentChunks: [DocumentChunk] = []
    /// term → document frequency (how many chunks contain the term)
    private var documentFrequency: [String: Int] = [:]
    private var averageChunkLength: Double = 0
    
    private var documentsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("RAG", isDirectory: true)
    }
    
    // MARK: - Embedding Provider
    
    /// Set by ServiceContainer to enable vector/hybrid search.
    /// When nil, falls back to BM25-only keyword search.
    var embeddingProvider: ((String) async throws -> [Float])?
    
    // MARK: - Backend label (for UI / debug)
    
    var retrievalBackend: String {
        embeddingProvider != nil ? "hybrid" : "bm25"
    }
    
    // MARK: - Document Ingestion
    
    /// Ingest a document file (PDF, TXT, MD) and return the number of chunks created.
    /// If an embedding provider is configured, also generates semantic vectors for each chunk.
    func ingestDocument(url: URL) async throws -> Int {
        let text = try extractText(from: url)
        let sourceName = url.lastPathComponent
        let chunks = chunkText(text, sourceName: sourceName)
        
        // Generate embeddings if provider is available
        if let provider = embeddingProvider {
            print("[RAGService] Generating embeddings for \(chunks.count) chunks...")
            for i in 0..<chunks.count {
                do {
                    let vec = try await provider(chunks[i].content)
                    documentChunks.append(DocumentChunk(
                        id: chunks[i].id,
                        content: chunks[i].content,
                        sourceName: chunks[i].sourceName,
                        chunkIndex: chunks[i].chunkIndex,
                        termFrequencies: chunks[i].termFrequencies,
                        length: chunks[i].length,
                        embedding: vec
                    ))
                } catch {
                    // Fall back: store chunk without embedding
                    print("[RAGService] Embedding failed for chunk \(i): \(error)")
                    documentChunks.append(chunks[i])
                }
            }
        } else {
            for chunk in chunks {
                documentChunks.append(chunk)
            }
        }
        
        rebuildIndex()
        try await saveChunks()
        
        let vecCount = documentChunks.filter { $0.embedding != nil }.count
        print("[RAGService] Ingested \(chunks.count) chunks from \(sourceName) (backend=\(retrievalBackend), embeddings=\(vecCount))")
        return chunks.count
    }
    
    /// Search for relevant chunks given a query.
    /// Uses hybrid search (BM25 + vector) when embeddings are available, BM25-only otherwise.
    func search(query: String, topK: Int = 3) async -> [DocumentChunk] {
        guard !documentChunks.isEmpty else { return [] }
        
        let queryTerms = tokenize(query)
        
        // Try vector search first if provider + embeddings exist
        let hasEmbeddings = documentChunks.contains { $0.embedding != nil }
        if let provider = embeddingProvider, hasEmbeddings, !queryTerms.isEmpty {
            do {
                let queryVec = try await provider(query)
                return hybridSearch(queryTerms: queryTerms, queryVec: queryVec, topK: topK)
            } catch {
                print("[RAGService] Vector search failed, falling back to BM25: \(error)")
            }
        }
        
        // BM25-only fallback
        return bm25Search(queryTerms: queryTerms, topK: topK)
    }
    
    /// BM25 keyword search (always available).
    private func bm25Search(queryTerms: [String], topK: Int) -> [DocumentChunk] {
        guard !queryTerms.isEmpty else { return [] }
        
        let n = Double(documentChunks.count)
        var scored: [(DocumentChunk, Double)] = []
        
        for chunk in documentChunks {
            let score = bm25Score(queryTerms: queryTerms, chunk: chunk, corpusSize: n)
            if score > 0 {
                scored.append((chunk, score))
            }
        }
        
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(topK).map { $0.0 })
    }
    
    /// Hybrid search: fuses BM25 keyword scores with cosine similarity scores.
    /// Uses `hybridAlpha` to weight BM25 vs vector contributions.
    private func hybridSearch(queryTerms: [String], queryVec: [Float], topK: Int) -> [DocumentChunk] {
        let n = Double(documentChunks.count)
        var scored: [(DocumentChunk, Double)] = []
        
        // Get raw BM25 scores for normalization
        var bm25Scores: [(Int, Double)] = []
        for (i, chunk) in documentChunks.enumerated() {
            let s = bm25Score(queryTerms: queryTerms, chunk: chunk, corpusSize: n)
            if s > 0 {
                bm25Scores.append((i, s))
            }
        }
        
        // Get raw vector scores
        var vecScores: [(Int, Double)] = []
        for (i, chunk) in documentChunks.enumerated() {
            if let emb = chunk.embedding {
                let s = Self.cosineSimilarity(queryVec, emb)
                vecScores.append((i, s))
            }
        }
        
        // Normalize scores to [0, 1] range using min-max
        let bm25Norm = normalizeScores(bm25Scores.map { $0.1 })
        let vecNorm = normalizeScores(vecScores.map { $0.1 })
        
        // Build a lookup for normalized BM25 scores
        var bm25Map: [Int: Double] = [:]
        for (idx, (i, _)) in bm25Scores.enumerated() {
            bm25Map[i] = bm25Norm[idx]
        }
        
        var vecMap: [Int: Double] = [:]
        for (idx, (i, _)) in vecScores.enumerated() {
            vecMap[i] = vecNorm[idx]
        }
        
        // Fuse scores
        for (i, chunk) in documentChunks.enumerated() {
            let bm = bm25Map[i] ?? 0
            let vc = vecMap[i] ?? 0
            let fused = hybridAlpha * bm + (1.0 - hybridAlpha) * vc
            if fused > 0 {
                scored.append((chunk, fused))
            }
        }
        
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(topK).map { $0.0 })
    }
    
    /// Compute cosine similarity between two L2-normalized vectors.
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0
        for i in 0..<a.count {
            dot += a[i] * b[i]
        }
        // Vectors are assumed L2-normalized; clamp to [-1, 1]
        return Double(max(-1, min(1, dot)))
    }
    
    /// Min-max normalize a list of scores to [0, 1].
    private func normalizeScores(_ scores: [Double]) -> [Double] {
        guard let mn = scores.min(), let mx = scores.max(), mx > mn else {
            return scores.map { _ in 1.0 }
        }
        return scores.map { ($0 - mn) / (mx - mn) }
    }
    
    /// Build RAG-augmented prompt for the chat/inference path.
    func augmentPrompt(userPrompt: String) async -> String {
        let relevantChunks = await search(query: userPrompt, topK: topK)
        
        guard !relevantChunks.isEmpty else {
            return userPrompt
        }
        
        let backend = retrievalBackend
        var context = "Relevant context from your documents (local \(backend) retrieval):\n\n"
        for chunk in relevantChunks {
            context += "--- Document: \(chunk.sourceName) ---\n"
            context += chunk.content + "\n\n"
        }
        
        context += "Based on the above context, please answer:\n\(userPrompt)"
        return context
    }
    
    /// List unique document source names for UI display.
    func documentSources() -> [String] {
        Array(Set(documentChunks.map { $0.sourceName })).sorted()
    }
    
    /// Remove all chunks belonging to a document source.
    func removeDocument(sourceName: String) {
        documentChunks.removeAll { $0.sourceName == sourceName }
        rebuildIndex()
        Task { try? await saveChunks() }
        print("[RAGService] Removed document: \(sourceName) (\(documentChunks.count) chunks remaining)")
    }
    
    /// Regenerate embeddings for all chunks that lack them (e.g., after loading legacy data).
    func generateAllEmbeddings() async {
        guard let provider = embeddingProvider else { return }
        var updated = false
        for i in 0..<documentChunks.count {
            if documentChunks[i].embedding == nil {
                do {
                    let vec = try await provider(documentChunks[i].content)
                    documentChunks[i].embedding = vec
                    updated = true
                } catch {
                    print("[RAGService] Embedding failed for chunk \(i): \(error)")
                }
            }
        }
        if updated {
            try? await saveChunks()
            let vecCount = documentChunks.filter { $0.embedding != nil }.count
            print("[RAGService] Generated embeddings: \(vecCount)/\(documentChunks.count) chunks")
        }
    }
    
    // MARK: - Text Extraction
    
    private func extractText(from url: URL) throws -> String {
        switch url.pathExtension.lowercased() {
        case "txt", "md", "markdown", "csv", "log":
            return try String(contentsOf: url, encoding: .utf8)
        case "pdf":
            return try extractPDFText(url: url)
        default:
            throw RAGError.unsupportedFormat(url.pathExtension)
        }
    }
    
    private func extractPDFText(url: URL) throws -> String {
        guard let pdf = PDFDocument(url: url) else {
            throw RAGError.pdfReadFailed
        }
        
        var fullText = ""
        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RAGError.pdfEmpty
        }
        
        return fullText
    }
    
    // MARK: - Text Chunking
    
    private func chunkText(_ text: String, sourceName: String) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        let words = text.split { $0.isWhitespace || $0.isNewline }.map(String.init)
        var index = 0
        
        while index < words.count {
            let end = min(index + maxChunkSize, words.count)
            let chunkWords = words[index..<end]
            let content = chunkWords.joined(separator: " ")
            
            let terms = tokenize(content)
            var tf: [String: Int] = [:]
            for t in terms {
                tf[t, default: 0] += 1
            }
            
            let chunk = DocumentChunk(
                id: UUID().uuidString,
                content: content,
                sourceName: sourceName,
                chunkIndex: chunks.count,
                termFrequencies: tf,
                length: terms.count
            )
            chunks.append(chunk)
            
            let step = max(1, maxChunkSize - chunkOverlap)
            index += step
        }
        
        return chunks
    }
    
    // MARK: - Tokenization
    
    /// Lowercase alphanumeric tokens (simple, fast, no model file).
    nonisolated private func tokenize(_ text: String) -> [String] {
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
    
    // MARK: - BM25
    
    private func rebuildIndex() {
        documentFrequency = [:]
        var totalLen = 0
        for chunk in documentChunks {
            totalLen += chunk.length
            for term in chunk.termFrequencies.keys {
                documentFrequency[term, default: 0] += 1
            }
        }
        averageChunkLength = documentChunks.isEmpty
            ? 0
            : Double(totalLen) / Double(documentChunks.count)
    }
    
    private func bm25Score(queryTerms: [String], chunk: DocumentChunk, corpusSize: Double) -> Double {
        guard corpusSize > 0, averageChunkLength > 0 else { return 0 }
        
        var score: Double = 0
        let dl = Double(max(chunk.length, 1))
        let avgdl = averageChunkLength
        
        // Unique query terms with simple query TF boost
        var qtf: [String: Int] = [:]
        for t in queryTerms { qtf[t, default: 0] += 1 }
        
        for (term, qf) in qtf {
            let tf = Double(chunk.termFrequencies[term] ?? 0)
            if tf == 0 { continue }
            
            let df = Double(documentFrequency[term] ?? 0)
            // IDF with +0.5 smoothing (Robertson/Sparck Jones style)
            let idf = log(1.0 + (corpusSize - df + 0.5) / (df + 0.5))
            let denom = tf + k1 * (1.0 - b + b * dl / avgdl)
            let termScore = idf * (tf * (k1 + 1.0)) / denom
            score += termScore * (1.0 + log(Double(qf)))
        }
        
        return score
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
        // Backward compatible: older chunks without termFrequencies re-tokenize
        let decoded = try JSONDecoder().decode([DocumentChunk].self, from: data)
        documentChunks = decoded.map { chunk in
            if chunk.termFrequencies.isEmpty {
                let terms = tokenize(chunk.content)
                var tf: [String: Int] = [:]
                for t in terms { tf[t, default: 0] += 1 }
                return DocumentChunk(
                    id: chunk.id,
                    content: chunk.content,
                    sourceName: chunk.sourceName,
                    chunkIndex: chunk.chunkIndex,
                    termFrequencies: tf,
                    length: terms.count,
                    embedding: chunk.embedding
                )
            }
            return chunk
        }
        rebuildIndex()
        
        let vecCount = documentChunks.filter { $0.embedding != nil }.count
        print("[RAGService] Loaded \(documentChunks.count) chunks (backend=\(retrievalBackend), embeddings=\(vecCount))")
        
        // If provider is available but chunks lack embeddings, generate them
        if embeddingProvider != nil && vecCount < documentChunks.count {
            print("[RAGService] Missing embeddings for \(documentChunks.count - vecCount) chunks — generating...")
            // Fire-and-forget: don't block UI on embedding generation
            Task { await generateAllEmbeddings() }
        }
    }
    
    // MARK: - Management
    
    func documentCount() -> Int {
        documentChunks.count
    }
    
    func chunkCount() -> Int {
        documentChunks.count
    }
    
    var hasEmbeddings: Bool {
        documentChunks.contains { $0.embedding != nil }
    }
    
    var embeddingCoverage: Double {
        guard !documentChunks.isEmpty else { return 0 }
        let with = documentChunks.filter { $0.embedding != nil }.count
        return Double(with) / Double(documentChunks.count)
    }
    
    func clearAll() {
        documentChunks.removeAll()
        documentFrequency.removeAll()
        averageChunkLength = 0
        try? FileManager.default.removeItem(at: documentsDirectory)
    }
}

// MARK: - Supporting Types

struct DocumentChunk: Identifiable, Codable {
    let id: String
    let content: String
    let sourceName: String
    let chunkIndex: Int
    /// Per-chunk term frequencies for BM25 (empty in legacy JSON → rebuilt on load)
    var termFrequencies: [String: Int]
    var length: Int
    /// Semantic embedding vector (nil when not yet generated or legacy data)
    var embedding: [Float]? = nil
    
    init(
        id: String,
        content: String,
        sourceName: String,
        chunkIndex: Int,
        termFrequencies: [String: Int] = [:],
        length: Int = 0,
        embedding: [Float]? = nil
    ) {
        self.id = id
        self.content = content
        self.sourceName = sourceName
        self.chunkIndex = chunkIndex
        self.termFrequencies = termFrequencies
        self.length = length > 0 ? length : max(termFrequencies.values.reduce(0, +), 0)
        self.embedding = embedding
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, sourceName, chunkIndex, termFrequencies, length, embedding
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        content = try c.decode(String.self, forKey: .content)
        sourceName = try c.decode(String.self, forKey: .sourceName)
        chunkIndex = try c.decode(Int.self, forKey: .chunkIndex)
        termFrequencies = try c.decodeIfPresent([String: Int].self, forKey: .termFrequencies) ?? [:]
        length = try c.decodeIfPresent(Int.self, forKey: .length) ?? 0
        embedding = try c.decodeIfPresent([Float].self, forKey: .embedding)
    }
}

enum RAGError: LocalizedError {
    case unsupportedFormat(String)
    case pdfReadFailed
    case pdfEmpty
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported file format: .\(ext)"
        case .pdfReadFailed:
            return "Could not read PDF file"
        case .pdfEmpty:
            return "PDF contains no extractable text"
        }
    }
}
