# ALIVE APPLE — Product Requirements Document (PRD)

**Version:** 1.0.0 (v1 Reduced Scope)  
**Target Platform:** iPhone 16 (A18, 8GB RAM) + USB-C storage  
**Status:** Production Design — Fast Tier Only

---

## 1. Executive Summary

ALIVE APPLE is a **pure on-device, local-first, privacy-max AI assistant** for iPhone 16. All inference runs locally on Apple Silicon via **MLX Swift**. Zero cloud dependency. Fully offline after model import.

v1 delivers **high-quality chat + vision on one fast, reliable model tier**. No multi-model orchestration, no RAG, no voice. The focus is **performance, stability, and thermal safety** — a polished experience that actually works well on real iPhone 16 hardware.

---

## 2. Core Principles

| Principle | Implementation |
|-----------|---------------|
| **Pure On-Device** | All LLM/VLM inference via MLX Swift on A18 GPU + ANE |
| **Local-First** | Works in airplane mode, no internet required |
| **Privacy-Max** | Everything local, no telemetry, zero data leaves device |
| **Fast & Responsive** | <2s time-to-first-token for chat, <5s for vision |
| **Memory Safe** | Stay under 5.5GB total RAM, aggressive model lifecycle |
| **Thermal Aware** | Monitor thermal state, throttle before iOS does |
| **One Model at a Time** | Either text LLM or vision VLM loaded, never both |

---

## 3. Target Hardware

- **Device:** iPhone 16 (A18: 6-core CPU, 5-core GPU, 16-core ANE)
- **RAM:** 8GB LPDDR5 — usable for models: ~5.5GB after OS overhead
- **Storage:** 128GB+ internal (~4GB for models)
- **External:** USB-C flash drive (exFAT) for model transfer
- **Thermal:** Passive cooling — must stay under thermal throttle threshold

---

## 4. Models (v1 — Fast Tier Only)

### 4.1 Text Model
| Property | Value |
|----------|-------|
| **Model** | Phi-4 Mini 3.8B Instruct |
| **Format** | MLX (4-bit quantized safetensors) |
| **Size on Disk** | ~2.4GB |
| **RAM at Runtime** | ~3.0GB |
| **Context** | 4096 tokens (practical limit for 8GB) |
| **Inference Speed** | ~20-30 tok/s on A18 GPU |
| **Why** | Best-in-class reasoning for sub-4B models. Dense architecture, efficient MLX port available via mlx-community. |

### 4.2 Vision Model
| Property | Value |
|----------|-------|
| **Model** | SmolVLM2 2.2B Instruct |
| **Format** | MLX (4-bit quantized safetensors) |
| **Size on Disk** | ~1.2GB |
| **RAM at Runtime** | ~1.8GB |
| **Context** | 2048 tokens |
| **Inference Speed** | ~3-5s per image analysis |
| **Why** | Purpose-built for efficient on-device vision. Small but capable for object ID, scene description, basic OCR. |

### 4.3 Memory Budget
| State | RAM Used | Headroom |
|-------|----------|----------|
| **Idle (no model)** | ~200 MB | ~7.8 GB |
| **Text model loaded** | ~3.2 GB | ~4.8 GB |
| **Vision model loaded** | ~2.0 GB | ~6.0 GB |
| **During inference** | +0.5-1.0 GB KV cache | — |

**Rule:** Never exceed 5.5GB total. Unload text model before loading vision model (and vice versa).

---

## 5. Feature Requirements (v1 — What Ships)

### 5.1 Chat Interface
- Streaming token display via `AsyncThrowingStream<String, Error>`
- Markdown rendering (headers, lists, code blocks, bold/italic)
- Clean system prompt giving ALIVE persona (private, on-device, honest)
- Persistent local chat history via SwiftData
- Chat export (JSON)

### 5.2 Vision
- Photo library upload → VLM analysis
- Camera capture → VLM analysis
- Use cases: object identification, plant ID, basic OCR, scene description
- Image resizing to 1024px max dimension before inference
- Clear loading state during vision inference

### 5.3 USB Model Import
- Detect GGUF/MLX models on connected USB-C drive
- Copy to app-local model store (~/Library/ALIVE_APPLE/Models/)
- Show import progress
- exFAT format verification

### 5.4 System Awareness
- Memory pressure monitoring → warn user, suggest model unload
- Thermal state monitoring → throttle or pause inference
- Battery level display
- Never inference when thermal state ≥ serious

### 5.5 Error Handling & UX
- Non-blocking UI (async/await throughout)
- Timeout: 120s for text, 60s for vision
- Graceful error messages (not crash dumps)
- Toast notifications for background events
- Confirmation dialogs for destructive actions

---

## 6. UI/UX Design

- **Native iOS** — SwiftUI, HIG-compliant, Dark Mode primary
- **Clean & Simple** — Chat tab, Vision tab, Models tab, Settings tab
- **Model status always visible** — which model is loaded, memory/thermal indicators
- **Streaming responses** — tokens appear in real-time, no freezes
- **Accessible** — Dynamic Type, VoiceOver, high contrast

---

## 7. Technical Architecture (v1 Simplified)

```
┌──────────────────────────────────────────────────┐
│                SwiftUI Layer                       │
│  ChatView │ VisionView │ ModelImportView │ Settings│
├──────────────────────────────────────────────────┤
│            ViewModels (@Observable, @MainActor)    │
│  ChatVM  │  SettingsVM  │  ModelVM                 │
├──────────────────────────────────────────────────┤
│           Services (Swift Actors)                  │
│  InferenceEngine │ ModelManager │ VisionService     │
│  USBImportService │ MemoryMonitor │ ThermalMonitor  │
├──────────────────────────────────────────────────┤
│         Inference Backend (MLX Swift)              │
│  MLXLLM / MLXLMCommon / MLXHuggingFace             │
├──────────────────────────────────────────────────┤
│         Apple Silicon (A18 GPU + ANE)              │
└──────────────────────────────────────────────────┘
```

---

## 8. Success Criteria

1. Text chat: time-to-first-token <2s for short prompts
2. Vision analysis: <5s for image + question
3. App stays responsive during inference (60fps scrolling)
4. RAM usage never exceeds 5.5GB total
5. No thermal throttling during 10+ minute chat sessions
6. Full offline (airplane mode) after model import
7. USB model import works with standard exFAT drives
8. 0 crashes from memory pressure in normal use

---

## 9. Non-Goals (v1 — Explicitly Deferred)

- 7B models (too large, too risky for 8GB RAM)
- Multi-model auto-routing (only one tier)
- RAG / document indexing
- Voice (STT/TTS)
- Pro tier / Grok API (fully offline)
- Agentic tool use
- Multi-model council
- iCloud sync
- Siri Shortcuts / Widgets
- On-device training / fine-tuning

---

*Built with MLX Swift — the best-performing, most native inference engine for Apple Silicon iOS.*
