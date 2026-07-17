# ALIVE APPLE — Product Requirements Document (PRD)

**Version:** 1.0.0  
**Target Platform:** iPhone 16 (A18, 8GB RAM) + 256GB exFAT USB Key  
**Project Path:** `ALIVE_APPLE/` (separate from main ALIVE Windows project)  
**Reference Only:** Main ALIVE (Windows, PyQt6, Ollama multi-model orchestration)  
**Status:** Production Design  

---

## 1. Executive Summary

ALIVE APPLE is a **pure on-device, local-first, privacy-max AI agent** for iPhone 16. All LLM/VLM inference runs locally on Apple Silicon (A18 Neural Engine + GPU). Zero cloud dependency for core inference. No PC remote heavy lifting. Fully offline-first after initial model setup.

The app provides multi-model orchestration with intelligent auto-routing across three tiers: **Fast** (light on-device), **Moderate** (stronger on-device), and **Pro** (Grok API via user-supplied key, internet-only).

---

## 2. Core Principles

| Principle | Implementation |
|-----------|---------------|
| **Pure On-Device** | All LLM/VLM inference runs on A18 Neural Engine + GPU via MLX/CoreML/llama.cpp |
| **Local-First** | Works in airplane mode. No internet required for core functionality. |
| **Privacy-Max** | Everything local. No telemetry. User controls API key. Zero data leaves device unless user explicitly opts into Pro tier. |
| **Zero Recurring Cost** | No subscription. User provides own API key for Pro tier only. |
| **Proactive with User Control** | Auto-routing with user confirmation gates. No hidden actions. |
| **iPhone 16 Optimized** | Respects 8GB RAM ceiling, A18 thermal limits, battery state. |

---

## 3. Target Hardware

- **Device:** iPhone 16 (A18 chip, 6-core CPU, 5-core GPU, 16-core Neural Engine)
- **RAM:** 8GB LPDDR5 (usable for models: ~5-6GB after OS overhead)
- **Storage:** 128GB+ internal
- **External:** 256GB USB-C flash drive (exFAT) for model storage/transfer
- **Thermal:** Passive cooling only — must monitor and throttle before throttling occurs

---

## 4. Model Tiers & Specifications

### 4.1 Fast Tier (On-Device, Always Available)
| Role | Model | Quant | Size |
|------|-------|-------|------|
| **Thinking (Text LLM)** | Phi-4 Mini 3.8B | Q4_K_M GGUF | ~2.4GB |
| **Vision (VLM)** | SmolVLM2 2.2B | Q4_K_M / CoreML | ~1.4GB |

### 4.2 Moderate Tier (On-Device, Load on Demand)
| Role | Model | Quant | Size |
|------|-------|-------|------|
| **Thinking (Text LLM)** | Qwen2.5 7B | Q4_K_M GGUF | ~4.4GB |
| **Vision (VLM)** | Qwen2.5-VL 7B | Q4_K_M GGUF | ~4.7GB |

### 4.3 Pro Tier (Cloud, Internet Required)
| Role | Model | Provider | Auth |
|------|-------|----------|------|
| **All Tasks** | Grok (xAI) | API | User Key (Keychain) |

### 4.4 Model Loading Strategy
- Fast tier loaded at app launch (always warm)
- Moderate tier loaded on-demand, unloaded when idle >5 min
- Only one text model + one vision model loaded simultaneously
- Max RAM budget: 5.5GB for models, leaving 2.5GB for iOS + app

---

## 5. Feature Requirements

### 5.1 Multi-Model Orchestration
- **Auto-Routing:** Intelligent offline route selection based on:
  - Task complexity (keyword + embedding analysis)
  - Current RAM pressure
  - Battery level
  - Thermal state
  - Historical performance metrics
- **Manual Override:** User can force any tier at any time
- **Council Mode (Future):** Run multiple models, compare outputs

### 5.2 Chat Interface
- Streaming token display (non-blocking UI)
- Markdown rendering (headers, lists, code blocks, tables)
- Image display inline
- Long-press for spellcheck/copy/select
- Persistent local chat history (CoreData/SwiftData)
- Chat export (JSON, Markdown)

### 5.3 Vision
- Camera live capture → VLM analysis
- Photo library upload → VLM analysis
- Use cases: object identification, plant ID, document scanning, basic OCR, scene description
- Image preprocessing for optimal VLM input (resize, normalize)

### 5.4 Voice
- On-device speech-to-text (Whisper via CoreML / Apple Speech framework)
- Text-to-speech output (AVSpeechSynthesizer or on-device model)
- Voice chat mode: continuous listening with VAD
- Hands-free operation support

### 5.5 RAG (Retrieval-Augmented Generation)
- Local document indexing (PDF, TXT, Markdown)
- On-device embeddings (all-MiniLM-L6-v2 CoreML)
- Local vector store (Swift-native or SQLite with vector extension)
- Context injection into prompts

### 5.6 USB Model Management
- Auto-detect GGUF/MLX/CoreML models on connected USB-C drive
- Import models to app's local storage
- Model deletion to free space
- exFAT format verification
- Keep ALIVE APPLE models separate from main ALIVE Windows models

### 5.7 Pro Tier (Grok API)
- Prompt user for API key on first Pro use
- Store securely in iOS Keychain
- One-tap apply in Settings
- Automatic fallback to Moderate tier when offline
- Clear visual indicator when using Pro/cloud

### 5.8 Error Handling & UX
- Non-blocking UI during inference (async/await throughout)
- Timeout handling (configurable, default 120s for on-device, 30s for API)
- Graceful degradation: if a model fails, fall back to next available tier
- Confirmation dialogs for destructive actions (delete chats, unload models)
- Toast notifications for background events

---

## 6. UI/UX Design Principles

- **Native iOS** — SwiftUI, HIG-compliant
- **Dark Mode** — primary, with light mode support
- **Fluent-inspired** — clean, depth-aware, smooth animations
- **Dashboard** — simple overview: model status, quick chat entry, tier selector
- **Non-blocking** — streaming responses, no freezes
- **Accessible** — Dynamic Type, VoiceOver, high contrast
- **Tier Indicator** — always visible: which model is active (Fast/Moderate/Pro/None)

---

## 7. Technical Architecture (High-Level)

```
┌──────────────────────────────────────────────┐
│                  SwiftUI Layer                │
│  Dashboard │ Chat │ Vision │ Settings │ Models│
├──────────────────────────────────────────────┤
│               ViewModels (MVVM)               │
│  ChatVM │ SettingsVM │ ModelVM │ VisionVM     │
├──────────────────────────────────────────────┤
│              Services (Actors)                │
│  InferenceEngine │ ModelManager │ AutoRouter  │
│  VoiceService │ VisionService │ RAGService    │
│  KeychainManager │ USBImportService           │
├──────────────────────────────────────────────┤
│         Inference Backends (C++/Metal)        │
│  llama.cpp │ MLX Swift │ CoreML (ANE)         │
├──────────────────────────────────────────────┤
│         Apple Silicon (A18 + ANE)             │
└──────────────────────────────────────────────┘
```

---

## 8. Privacy & Security

- All inference on-device (Fast/Moderate tiers)
- Pro tier: API key in Keychain, HTTPS only, user-initiated
- No analytics, no telemetry, no crash reporting without user opt-in
- No data leaves device unless Pro tier is active and user sends a query
- Local chat history stored in app sandbox only
- No background network requests

---

## 9. Success Criteria

1. Fast tier responds in <2 seconds for short prompts
2. Moderate tier responds in <8 seconds for complex reasoning
3. Vision analysis completes in <5 seconds
4. App stays responsive (never blocks main thread)
5. RAM usage never exceeds 7GB total
6. No thermal throttling during normal use (5+ minute sessions)
7. Full offline functionality (airplane mode)
8. USB model import works with standard exFAT drives

---

## 10. Non-Goals (v1.0)

- Multi-modal council (run multiple models simultaneously and compare)
- iCloud sync of chat history
- Siri Shortcuts integration
- Widgets
- Apple Watch companion
- Training/fine-tuning on device
- Agentic tool-use beyond vision + RAG

---

*Reference: ALIVE Windows project — local-first, multi-model, sub-agents, vision, error handling.  
ALIVE APPLE adapts these principles to iOS on-device constraints.*
