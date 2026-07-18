# ALIVE APPLE — Model Inventory (v1)

**Version:** 1.0.0  
**Backend:** MLX Swift (safetensors, 4-bit quantized)  
**Scope:** Fast tier only — one text model, one vision model

---

## 1. Text Model — Phi-4 Mini 3.8B

| Property | Value |
|----------|-------|
| **Model** | Phi-4 Mini Instruct (microsoft/Phi-4-mini-instruct) |
| **Parameters** | 3.8B |
| **Quantization** | 4-bit (MLX) |
| **Format** | safetensors (MLX-compatible) |
| **Size on Disk** | ~2.4 GB |
| **RAM at Runtime** | ~3.0 GB |
| **Context Window** | 4096 tokens (practical for 8GB) |
| **Inference Speed** | ~20-30 tok/s on A18 GPU |
| **Best For** | Quick answers, reasoning, chat, summarization |
| **HuggingFace (MLX)** | `mlx-community/Phi-4-mini-instruct-4bit` |

**Why this model:** Microsoft's Phi-4 series is the best dense sub-4B reasoning model. At 4-bit MLX quantization it fits ~2.4GB on disk and uses ~3GB at runtime, leaving comfortable headroom on 8GB devices. MLX port from mlx-community is actively maintained.

---

## 2. Vision Model — SmolVLM2 2.2B

| Property | Value |
|----------|-------|
| **Model** | SmolVLM2 2.2B Instruct (HuggingFaceM4/SmolVLM2-2.2B-Instruct) |
| **Parameters** | 2.2B (LLM) + SigLIP 400M (vision encoder) |
| **Quantization** | 4-bit (MLX) |
| **Format** | safetensors (MLX-compatible) |
| **Size on Disk** | ~1.2 GB |
| **RAM at Runtime** | ~1.8 GB |
| **Context Window** | 2048 tokens |
| **Inference Speed** | ~3-5s per image |
| **Best For** | Object ID, scene description, basic OCR, plant ID |
| **HuggingFace (MLX)** | `mlx-community/SmolVLM2-2.2B-Instruct-4bit` |

**Why this model:** Purpose-built for efficient on-device vision. SigLIP vision encoder is fast and small. At 2.2B total, it's the most efficient VLM that still gives usable results. MLX port handles the vision encoder natively.

---

## 3. Memory Budget (v1)

| State | RAM Used | Headroom |
|-------|----------|----------|
| **App idle (no model)** | ~200 MB | ~7.8 GB |
| **Text model loaded** | ~3.2 GB | ~4.8 GB |
| **Vision model loaded** | ~2.0 GB | ~6.0 GB |
| **During inference** | +0.5-1.0 GB (KV cache) | — |

**Safety rules:**
- Never load both text + vision simultaneously
- Unload before switching models
- Total RAM ceiling: 5.5 GB
- Unload model if MemoryMonitor reports `.warning` or `.critical`

---

## 4. Model Acquisition

### Option A: Pre-quantized from mlx-community (recommended)

```bash
# Download from HuggingFace to USB drive
huggingface-cli download mlx-community/Phi-4-mini-instruct-4bit \
  --local-dir /Volumes/ALIVE_USB/Models/phi-4-mini/

huggingface-cli download mlx-community/SmolVLM2-2.2B-Instruct-4bit \
  --local-dir /Volumes/ALIVE_USB/Models/smolvlm2/
```

### Option B: Self-quantize from source

```python
# Requires MLX Python on Mac
import mlx.core as mx
from mlx_lm import convert, quantize

# Convert + quantize in one step
convert("microsoft/Phi-4-mini-instruct", quantize=True, q_group_size=64, q_bits=4)
```

### Option C: USB transfer flow

1. Download models to USB-C drive (exFAT) using any computer
2. Plug USB into iPhone 16
3. Open ALIVE APPLE → Models → Import from USB
4. App copies safetensors to local storage
5. Model ready for loading

---

## 5. Model Validation

Each imported model directory must contain:
- `*.safetensors` — weight files (at least one)
- `config.json` — model configuration
- `tokenizer.json` or `tokenizer_config.json` — tokenizer
- Optional: `*.model` — sentencepiece model (if used)

Validation checks:
1. Directory contains required files
2. `config.json` parses successfully
3. architecture matches known supported types (phi4, smolvlm, etc.)
4. Total file size reasonable (1-5 GB)

---

## 6. Future Model Candidates (v2+)

| Model | Parameters | Why |
|-------|-----------|-----|
| Gemma 3 4B | 4B | Google's latest small model, strong reasoning |
| Llama 4 Scout (when mobile-optimized) | 17B MoE (~4B active) | MoE architecture efficient on device |
| Phi-4-Vision | ~4B | Microsoft's VLM entry, may replace SmolVLM2 |
| Qwen 3 4B | 4B | Next-gen Qwen, competitive with Phi-4 |

---

*All models use MLX 4-bit quantization. Download from mlx-community on HuggingFace for pre-quantized MLX-compatible safetensors.*
