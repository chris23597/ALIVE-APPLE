# ALIVE APPLE — Model Inventory

**Version:** 1.0.0  
**Quantization:** Q4_K_M (or best equivalent for speed/quality balance on 8GB)  
**Minimum Model Size:** 5B+ parameters (except SmolVLM2 2.2B for vision fast tier)  

---

## 1. Text LLM Models (Thinking/Reasoning)

### Fast Tier — Phi-4 Mini 3.8B Q4_K_M

| Property | Value |
|----------|-------|
| **Model** | Phi-4 Mini Instruct (microsoft/Phi-4-mini-instruct) |
| **Parameters** | 3.8B |
| **Quant** | Q4_K_M |
| **Format** | GGUF |
| **Size on Disk** | ~2.4 GB |
| **RAM at Runtime** | ~2.8 GB |
| **Context Window** | 128K tokens |
| **Best For** | Quick answers, simple reasoning, chat, summarization |
| **Inference Speed** | ~15-25 tok/s on A18 GPU |
| **HuggingFace** | `unsloth/Phi-4-mini-instruct-GGUF` |
| **Direct GGUF** | `Phi-4-mini-instruct-Q4_K_M.gguf` |

**Why this model:** Microsoft's Phi-4 series is dense, efficient, and punches above its weight class. At 3.8B with Q4_K_M it fits comfortably in ~2.4GB, leaving room for the vision model.

---

### Moderate Tier — Qwen2.5 7B Q4_K_M

| Property | Value |
|----------|-------|
| **Model** | Qwen2.5 7B Instruct (Qwen/Qwen2.5-7B-Instruct) |
| **Parameters** | 7.6B |
| **Quant** | Q4_K_M |
| **Format** | GGUF |
| **Size on Disk** | ~4.4 GB |
| **RAM at Runtime** | ~4.8 GB |
| **Context Window** | 32K tokens (128K native, limited for RAM) |
| **Best For** | Complex reasoning, multi-step problems, deep analysis |
| **Inference Speed** | ~8-12 tok/s on A18 GPU |
| **HuggingFace** | `bartowski/Qwen2.5-7B-Instruct-GGUF` |
| **Direct GGUF** | `qwen2.5-7b-instruct-Q4_K_M.gguf` |

**Why this model:** Qwen2.5 7B is currently the best-in-class 7B model for reasoning tasks. Q4_K_M keeps quality high while fitting in ~4.4GB on disk. Combined with SmolVLM2 (1.4GB), total is ~5.8GB — tight but within budget with aggressive memory management.

---

## 2. Vision/Multimodal Models (VLM)

### Fast Tier — SmolVLM2 2.2B (or optimized equivalent)

| Property | Value |
|----------|-------|
| **Model** | SmolVLM2 2.2B (HuggingFaceM4/SmolVLM2-2.2B-Instruct) |
| **Parameters** | 2.2B |
| **Quant** | Q4_K_M / CoreML |
| **Format** | GGUF (preferred) or CoreML .mlmodelc |
| **Size on Disk** | ~1.0 GB (GGUF) / ~1.1 GB (CoreML) |
| **RAM at Runtime** | ~1.8 GB |
| **Vision Encoder** | SigLIP 400M |
| **Best For** | Quick image description, object ID, basic OCR |
| **Inference Speed** | ~2-4 seconds per image |
| **HuggingFace** | `ggml-org/SmolVLM2-2.2B-Instruct-GGUF` |

**Why this model:** SmolVLM2 is purpose-built for efficient on-device vision. At 2.2B it's the only sub-5B model in our lineup — justified because vision has different quality/size tradeoffs than text. It can describe images, identify common objects, and do basic OCR at acceptable quality for its size.

---

### Moderate Tier — Qwen2.5-VL 7B Q4_K_M

| Property | Value |
|----------|-------|
| **Model** | Qwen2.5-VL 7B Instruct (Qwen/Qwen2.5-VL-7B-Instruct) |
| **Parameters** | 7.6B (LLM) + vision encoder |
| **Quant** | Q4_K_M |
| **Format** | GGUF (llama.cpp with vision patch) |
| **Size on Disk** | ~4.4 GB |
| **RAM at Runtime** | ~5.0 GB |
| **Context Window** | 32K tokens |
| **Best For** | Detailed analysis, plant ID, document understanding, complex VQA |
| **Inference Speed** | ~4-8 seconds per image |
| **HuggingFace** | `unsloth/Qwen2.5-VL-7B-Instruct-GGUF` |

**Why this model:** Qwen2.5-VL is state-of-the-art for 7B-class vision-language models. Excellent at detailed descriptions, document parsing, and nuanced visual Q&A. This is the premium on-device vision experience. Note: when Moderate VLM is loaded (~5.0GB), the Moderate text LLM must be unloaded. Fast text LLM can coexist (~2.8GB + ~5.0GB = ~7.8GB — too tight). Practical strategy: load Moderate VLM alone, use Fast LLM for text concurrently.

---

## 3. Pro Tier — Grok API (xAI)

| Property | Value |
|----------|-------|
| **Provider** | xAI (Grok) |
| **Endpoint** | `https://api.x.ai/v1/chat/completions` |
| **Model ID** | `grok-2` (or latest) |
| **Vision** | Supported (image uploads via API) |
| **Auth** | Bearer token (user-supplied API key) |
| **Cost** | Per-token (user pays xAI directly) |
| **Latency** | ~1-3 seconds (cloud) |
| **Requirement** | Internet connection |

---

## 4. Support Models

### Embeddings — all-MiniLM-L6-v2 (CoreML)

| Property | Value |
|----------|-------|
| **Model** | all-MiniLM-L6-v2 (sentence-transformers) |
| **Parameters** | 22M |
| **Format** | CoreML .mlmodelc |
| **Size on Disk** | ~90 MB |
| **RAM at Runtime** | ~120 MB |
| **Purpose** | RAG document embeddings |
| **HuggingFace** | `sentence-transformers/all-MiniLM-L6-v2` |

### Whisper (STT) — whisper-small (CoreML)

| Property | Value |
|----------|-------|
| **Model** | OpenAI Whisper Small |
| **Parameters** | 244M |
| **Format** | CoreML .mlmodelc |
| **Size on Disk** | ~180 MB |
| **RAM at Runtime** | ~500 MB (transient, released after transcription) |
| **Purpose** | On-device speech-to-text |
| **Alternative** | Apple Speech framework (built-in, zero size) |

---

## 5. Memory Budget Table

| Scenario | Models Loaded | RAM Used | Headroom |
|----------|--------------|----------|----------|
| **Idle** | None | ~200 MB | ~7.8 GB |
| **Fast Text only** | Phi-4 Mini 3.8B | ~3.0 GB | ~5.0 GB |
| **Fast Text + Fast Vision** | Phi-4 Mini + SmolVLM2 | ~4.8 GB | ~3.2 GB |
| **Moderate Text only** | Qwen2.5 7B | ~5.0 GB | ~3.0 GB |
| **Fast Text + Moderate Vision** | Phi-4 Mini + Qwen2.5-VL 7B | ~7.8 GB | ~0.2 GB ⚠️ |
| **Moderate Vision only** | Qwen2.5-VL 7B | ~5.2 GB | ~2.8 GB |
| **All support** | Embeddings + Whisper | ~0.8 GB (transient) | varies |

⚠️ **Fast Text + Moderate Vision** is technically possible but leaves only ~200MB headroom. iOS may kill background apps. Use only when explicitly requested, and unload immediately after.

---

## 6. Download Links

### HuggingFace Repositories

| Model | URL |
|-------|-----|
| Phi-4 Mini 3.8B Q4_K_M | https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF |
| Qwen2.5 7B Q4_K_M | https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF |
| SmolVLM2 2.2B | https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF |
| Qwen2.5-VL 7B Q4_K_M | https://huggingface.co/unsloth/Qwen2.5-VL-7B-Instruct-GGUF |
| all-MiniLM-L6-v2 | https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2 |
| Whisper Small CoreML | https://huggingface.co/openai/whisper-small |

### Direct GGUF Downloads (for USB transfer)

Use `Scripts/download_models.sh` to batch-download to USB key.

---

## 7. Model Validation

Each imported model must pass validation:
1. **File extension check:** `.gguf`, `.mlx`, `.mlmodelc`
2. **Magic bytes:** GGUF header validation for `.gguf` files
3. **Size range:** 500MB – 6GB (reject obviously wrong sizes)
4. **Metadata read:** Extract model name, param count, quant from GGUF header
5. **SHA-256 checksum** against known-good hashes (optional, configurable)

---

## 8. Future Model Candidates (v2.0+)

| Model | Why |
|-------|-----|
| Llama 4 Scout (when GGUF available) | 17B MoE, could fit with aggressive quant |
| Qwen3 8B (when released) | Next-gen reasoning |
| Phi-4-Vision | Microsoft's VLM entry |
| DeepSeek-V2 Lite (when mobile-optimized) | MoE architecture, efficient |
| MLX-native Mistral 7B | First-class Apple Silicon support |

---

*All models use Q4_K_M quantization unless otherwise noted.  
Download the exact GGUF files listed — do not download full safetensors and self-quantize unless needed.*
