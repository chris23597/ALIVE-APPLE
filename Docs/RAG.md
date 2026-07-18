# RAG (no Mac required)

ALIVE APPLE uses **BM25 keyword retrieval** for document RAG.

- No `EmbeddingModel.mlmodelc` / CoreML conversion step
- Works on Windows development + GitHub Actions iOS builds
- API: `RAGService.ingestDocument`, `search`, `augmentPrompt` (unchanged for ChatViewModel)

Optional later (Mac only): ship a real MiniLM CoreML model as a quality upgrade — not required for shipping.
