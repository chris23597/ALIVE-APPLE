# ALIVE APPLE

**Pure on-device, local-first, privacy-max AI agent for iPhone 16.**

> All LLM/VLM inference runs locally on Apple Silicon. Zero cloud dependency for core inference. Fully offline-first after initial model setup.

---

## Quick Start

1. **Format USB drive as exFAT** → See [USB_SETUP.md](USB_SETUP.md)
2. **Download models to USB** → `bash Scripts/download_models.sh`
3. **Build the app** in Xcode 17 → See [BUILD_GUIDE.md](BUILD_GUIDE.md)
4. **Plug USB into iPhone 16** → Import models in-app
5. **Start chatting** — fully offline, on-device AI

---

## What is ALIVE APPLE?

ALIVE APPLE is the iOS-native adaptation of the ALIVE project — a multi-model, auto-routing, fully offline AI agent. It runs local LLMs and VLMs directly on iPhone 16 hardware.

### Core Features

| Feature | Description |
|---------|-------------|
| 🤖 **Multi-Model** | Fast (Phi-4 Mini 3.8B) + Moderate (Qwen2.5 7B) + Pro (Grok API) |
| 🧠 **Auto-Routing** | Intelligent tier selection based on task complexity, thermal, battery, memory |
| 👁️ **Vision** | Camera/gallery → VLM analysis (plant ID, OCR, scene description) |
| 🎤 **Voice** | On-device speech-to-text + text-to-speech |
| 📄 **RAG** | Local document indexing with semantic search |
| 🔒 **Privacy-Max** | Everything local. No telemetry. Your data never leaves the device. |
| 📡 **Offline-First** | Works in airplane mode |
| 💾 **USB Import** | Import Q4_K_M GGUF models from exFAT USB-C drive |

### Model Tiers

```
Fast ───→ Phi-4 Mini 3.8B  + SmolVLM2 2.2B    On-device, always ready
Moderate → Qwen2.5 7B      + Qwen2.5-VL 7B    On-device, load on demand
Pro ────→ Grok API (xAI)                       Cloud, requires API key
```

---

## Project Structure

```
ALIVE_APPLE/
├── README.md                    # You are here
├── PRD.md                       # Full Product Requirements
├── ARCHITECTURE.md              # System architecture & design
├── MODEL_INVENTORY.md           # Model specs & download links
├── BUILD_GUIDE.md               # Step-by-step build instructions
├── TESTING_PLAN.md              # Test strategy & test cases
├── USB_SETUP.md                 # exFAT USB key setup guide
├── Docs/
│   ├── ROUTING.md               # Auto-routing logic deep-dive
│   ├── VOICE.md                 # Voice integration details
│   ├── API_KEY.md               # Grok API key integration
│   └── UI_MOCKUPS.md            # UI design system & mockups
├── ALIVE_APPLE/                 # Swift source code
│   ├── Models/                  # Data models
│   ├── Services/                # Business logic (Actors)
│   ├── Views/                   # SwiftUI views
│   ├── ViewModels/              # MVVM ViewModels
│   └── Utils/                   # Thermal & memory monitors
└── Scripts/
    ├── download_models.sh       # Batch download all models
    └── convert_to_coreml.py     # Convert HF models to CoreML
```

---

## Requirements

| Component | Requirement |
|-----------|-------------|
| **Device** | iPhone 16 (A18, 8GB RAM) |
| **OS** | iOS 18+ |
| **Build** | macOS 15+ (Sequoia), Xcode 17+ |
| **Storage** | ~14GB free for all 4 models |
| **USB** | USB-C drive, 256GB, exFAT formatted |
| **Optional** | xAI API key for Grok Pro tier |

---

## Key Design Decisions

1. **Pure on-device** — No PC for inference. iPhone handles everything locally.
2. **Q4_K_M quantization** — Best speed/quality balance for 8GB RAM.
3. **Two on-device tiers** — Fast (always loaded) + Moderate (on demand).
4. **llama.cpp + CoreML** — GGUF for LLMs, CoreML for embeddings & Whisper.
5. **iOS actors** — Thread-safe services using Swift actors.
6. **MVVM + @Observable** — Modern SwiftUI architecture.
7. **Separate from ALIVE Windows** — This is a fresh iOS-native project. ALIVE Windows is reference only.

---

## From USB to Inference in 5 Minutes

```bash
# 1. Download models to USB (on any computer)
bash Scripts/download_models.sh

# 2. Plug USB into iPhone 16
# 3. Open ALIVE APPLE → Models → Import from USB
# 4. Fast tier loads automatically (Phi-4 Mini 3.8B)
# 5. Start chatting!
```

---

## Related Projects

- **ALIVE (Windows):** The original local-first AI agent (PyQt6, Ollama). Reference only for architecture patterns.
- **PocketPal / Off Grid:** Community on-device LLM projects for inspiration on llama.cpp iOS integration.

---

*Built for iPhone 16. Optimized for Apple Silicon. Designed for offline freedom.*
