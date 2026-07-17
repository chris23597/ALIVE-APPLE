import Foundation
import PDFKit

/// Local RAG (Retrieval-Augmented Generation) — **no Mac / no CoreML required**.
///
/// Default retrieval is **BM25-style keyword search** over chunked documents.
/// That keeps ingest + search fully on-device and functional without
/// `EmbeddingModel.mlmodelc` (which can only be compiled on a Mac).
///
/// Optional: if a future CoreML embedding bundle is dropped into Resources,
/// vector search can be layered later without changing the public API.
actor RAGService {
    
    // MARK: - Configuration
    
    private let maxChunkSize = 512       // words per chunk
    private let chunkOverlap = 50
    private let topK = 3
    
    // BM25 hyperparameters (classic defaults)
    private let k1: Double = 1.2
    private let b: Double = 0.75
    
    // MARK: - Document Storage
    
    private var documentChunks: [DocumentChunk] = []
    /// term → document frequency (how many chunks contain the term)
    private var documentFrequency: [String: Int] = [:]
    private var averageChunkLength: Double = 0
    
    private var documentsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("RAG", isDirectory: true)
    }
    
    // MARK: - Backend label (for UI / debug)
    
    /// Always "bm25" until a real embedding model is shipped without Mac conversion.
    var retrievalBackend: String { "bm25" }
    
    // MARK: - Document Ingestion
    
    /// Ingest a document file (PDF, TXT, MD) and return the number of chunks created.
    func ingestDocument(url: URL) async throws -> Int {
        let text = try extractText(from: url)
        let sourceName = url.lastPathComponent
        let chunks = chunkText(text, sourceName: sourceName)
        
        for chunk in chunks {
            documentChunks.append(chunk)
        }
        
        rebuildIndex()
        try await saveChunks()
        
        print("[RAGService] Ingested \(chunks.count) chunks from \(sourceName) (backend=\(retrievalBackend))")
        return chunks.count
    }
    
    /// Search for relevant chunks given a query (BM25 keyword ranking).
    func search(query: String, topK: Int = 3) async -> [DocumentChunk] {
        guard !documentChunks.isEmpty else { return [] }
        
        let queryTerms = tokenize(query)
        guard !queryTerms.isEmpty else { return [] }
        
        let n = Double(documentChunks.count)
        var scored: [(DocumentChunk, Double)] = []
        
        for chunk in documentChunks {
            let score = bm25Score(
                queryTerms: queryTerms,
                chunk: chunk,
                corpusSize: n
            )
            if score > 0 {
                scored.append((chunk, score))
            }
        }
        
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(topK).map { $0.0 })
    }
    
    /// Build RAG-augmented prompt for the chat/inference path.
    func augmentPrompt(userPrompt: String) async -> String {
        let relevantChunks = await search(query: userPrompt, topK: topK)
        
        guard !relevantChunks.isEmpty else {
            return userPrompt
        }
        
        var context = "Relevant context from your documents (local BM25 retrieval):\n\n"
        for chunk in relevantChunks {
            context += "--- Document: \(chunk.sourceName) ---\n"
            context += chunk.content + "\n\n"
        }
        
        context += "Based on the above context, please answer:\n\(userPrompt)"
        return context
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
                    length: terms.count
                )
            }
            return chunk
        }
        rebuildIndex()
        print("[RAGService] Loaded \(documentChunks.count) chunks (backend=\(retrievalBackend))")
    }
    
    // MARK: - Management
    
    func documentCount() -> Int {
        documentChunks.count
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
    
    init(
        id: String,
        content: String,
        sourceName: String,
        chunkIndex: Int,
        termFrequencies: [String: Int] = [:],
        length: Int = 0
    ) {
        self.id = id
        self.content = content
        self.sourceName = sourceName
        self.chunkIndex = chunkIndex
        self.termFrequencies = termFrequencies
        self.length = length > 0 ? length : max(termFrequencies.values.reduce(0, +), 0)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, sourceName, chunkIndex, termFrequencies, length
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        content = try c.decode(String.self, forKey: .content)
        sourceName = try c.decode(String.self, forKey: .sourceName)
        chunkIndex = try c.decode(Int.self, forKey: .chunkIndex)
        termFrequencies = try c.decodeIfPresent([String: Int].self, forKey: .termFrequencies) ?? [:]
        length = try c.decodeIfPresent(Int.self, forKey: .length) ?? 0
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
