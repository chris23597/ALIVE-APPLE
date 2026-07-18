# ALIVE APPLE — System Architecture (v1)

**Version:** 1.0.0  
**Target:** iPhone 16 (A18, 8GB RAM)  
**Backend:** MLX Swift (mlx-swift + mlx-swift-lm)  
**Pattern:** SwiftUI + MVVM + Swift Actors

---

## 1. Architecture Overview

v1 is a **single-model, local-only** architecture. No auto-routing, no multi-tier orchestration, no cloud fallback. One model loaded at a time — either the text LLM or the vision VLM — never both simultaneously.

```
┌──────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌──────────┐    │
│  │ ChatView │  │VisionView│  │ModelImportView│  │Settings  │    │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘  └────┬─────┘    │
│       │              │               │                │          │
│  ┌────┴──────────────┴───────────────┴────────────────┴─────┐    │
│  │           ViewModels (@Observable, @MainActor)            │    │
│  │  ChatVM (streaming, history)                               │    │
│  │  ModelVM (import, load/unload, memory/thermal status)     │    │
│  │  SettingsVM (preferences, model info)                     │    │
│  └──────────────────────────┬───────────────────────────────┘    │
├─────────────────────────────┼────────────────────────────────────┤
│                     BUSINESS LOGIC LAYER                          │
│  ┌──────────────────────────┴───────────────────────────────┐    │
│  │               Services (Swift Actors)                      │    │
│  │                                                            │    │
│  │  ┌────────────────┐  ┌────────────────┐                    │    │
│  │  │InferenceEngine │  │  ModelManager  │                    │    │
│  │  │    (Actor)     │  │    (Actor)     │                    │    │
│  │  │                │  │                │                    │    │
│  │  │ - load()       │  │ - importModel()│                    │    │
│  │  │ - generate()   │  │ - discoverModels│                   │    │
│  │  │ - unload()     │  │ - validateModel│                    │    │
│  │  │ - embedText()  │  │ - memoryBudget │                    │    │
│  │  └───────┬────────┘  └───────┬────────┘                    │    │
│  │          │                   │                              │    │
│  │  ┌───────┴────────┐  ┌──────┴─────────┐                    │    │
│  │  │ VisionService  │  │USBImportService│                    │    │
│  │  │    (Actor)     │  │    (Actor)     │                    │    │
│  │  │                │  │                │                    │    │
│  │  │ - analyze()    │  │ - detectDrive()│                    │    │
│  │  │ - preprocess() │  │ - scanModels() │                    │    │
│  │  │ - dispatchVLM()│  │ - importToLocal│                    │    │
│  │  └────────────────┘  └────────────────┘                    │    │
│  │                                                            │    │
│  │  ┌────────────────┐  ┌────────────────┐                    │    │
│  │  │ MemoryMonitor  │  │ ThermalMonitor │                    │    │
│  │  │ - pressureLevel│  │ - thermalState │                    │    │
│  │  │ - warnThreshold│  │ - throttleGate │                    │    │
│  │  └────────────────┘  └────────────────┘                    │    │
│  └──────────────────────────┬───────────────────────────────┘    │
├─────────────────────────────┼────────────────────────────────────┤
│                    INFERENCE BACKEND                              │
│  ┌──────────────────────────┴───────────────────────────────┐    │
│  │                     MLX Swift                              │    │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐    │    │
│  │  │  MLXLLM  │  │ MLXLMCommon  │  │ MLXHuggingFace   │    │    │
│  │  │ (models) │  │ (ChatSession)│  │ (download/load)  │    │    │
│  │  └────┬─────┘  └──────┬───────┘  └────────┬─────────┘    │    │
│  │       │               │                    │               │    │
│  │  ┌────┴───────────────┴────────────────────┴─────┐         │    │
│  │  │            Model File Store                    │         │    │
│  │  │  ~/Library/ALIVE_APPLE/Models/                 │         │    │
│  │  │  - phi-4-mini/     (safetensors + config)     │         │    │
│  │  │  - smolvlm2/       (safetensors + config)     │         │    │
│  │  └───────────────────────────────────────────────┘         │    │
│  └────────────────────────────────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│                   APPLE SILICON (A18)                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │CPU Cores │  │GPU Cores │  │Neural Eng│  │ 8GB RAM  │        │
│  │  (6)     │  │   (5)    │  │  (16)    │  │ LPDDR5   │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Details

### 2.1 Presentation Layer (SwiftUI + MVVM)

All views are pure SwiftUI. ViewModels are `@Observable` classes annotated `@MainActor`. Views inject a shared `ServiceContainer` via `.environment()`.

**Key Views:**
| View | Purpose |
|------|---------|
| `ChatView` | Streaming chat with Markdown, model/thermal status bar |
| `VisionView` | Photo picker + camera + VLM results |
| `ModelImportView` | USB drive detection + model import workflow |
| `SettingsView` | Preferences, model info, memory/thermal gauges |

### 2.2 Business Logic Layer (Swift Actors)

All services are `actor` types. ViewModels never hold references to actors directly — they go through `ServiceContainer`.

#### `InferenceEngine` (Actor)

The heart of the app. Wraps MLX Swift's model loading and text generation.

```swift
actor InferenceEngine {
    func loadModel(_ config: ModelConfig) async throws
    func generate(prompt: String, maxTokens: Int) -> AsyncThrowingStream<String, Error>
    func generateVision(image: Data, prompt: String) -> AsyncThrowingStream<String, Error>
    func unloadModel()
    func embedText(_ text: String) async throws -> [Float]
    var isLoaded: Bool { get }
    var activeModelId: String? { get }
}
```

**Key design decisions:**
- Uses `MLXLLM` model loading via `#huggingFaceLoadModelContainer`
- Uses `ChatSession` from MLXLMCommon for streaming chat with history
- One model loaded at a time — `loadModel()` auto-unloads previous
- Returns `AsyncThrowingStream<String, Error>` for SwiftUI streaming — non-blocking, cancellable
- Vision path: loads VLM, preprocesses image, generates analysis
- Memory: model is unloaded from GPU when `unloadModel()` is called

#### `ModelManager` (Actor)

Manages model files and loading lifecycle.

```swift
actor ModelManager {
    func discoverModels() -> [ModelConfig]
    func importModel(from url: URL) async throws
    func validateModel(at url: URL) -> Bool
    func ensureTextModelLoaded() async throws -> ModelConfig
    func ensureVisionModelLoaded() async throws -> ModelConfig
    func unloadCurrentModel()
    var memoryBudget: (used: Int, limit: Int) { get }
}
```

**Key rules:**
- Text model loaded → vision request: unload text, load vision, run, unload vision, reload text
- Vision model loaded → chat request: unload vision, load text, keep text loaded
- Checks memory pressure before loading — refuses if >5.5GB
- Model files stored in `Documents/Models/`

#### `VisionService` (Actor)

Image preprocessing and VLM dispatch.

```swift
actor VisionService {
    func analyze(image: Data, prompt: String) -> AsyncThrowingStream<String, Error>
    func preprocessImage(_ data: Data, maxDimension: CGFloat) -> Data?
    func sourceType(_ data: Data) -> ImageSource  // camera vs library metadata
}
```

#### `USBImportService` (Actor)

USB drive detection and model import.

```swift
actor USBImportService {
    func detectUSBDrive() -> URL?
    func scanForModels(at url: URL) -> [URL]
    func importModel(from sourceURL: URL, to destURL: URL) async throws -> Progress
}
```

#### `MemoryMonitor` & `ThermalMonitor`

Lightweight observers that expose `@MainActor` state for UI consumption.

### 2.3 Inference Backend: MLX Swift

| Package | Purpose |
|---------|---------|
| `mlx-swift` | Core MLX array framework for Apple Silicon |
| `mlx-swift-lm` (MLXLLM, MLXLMCommon, MLXHuggingFace) | LLM/VLM model loading, chat session, streaming generation |
| `swift-huggingface` (HuggingFace) | Model download from HuggingFace Hub |
| `swift-transformers` (Tokenizers) | Tokenizer loading |

**Why MLX Swift over llama.cpp:**
1. **Pure Swift** — no C++ bridge, simpler build, better compile times
2. **Native GPU** — MLX uses Metal Performance Shaders directly, best GPU utilization
3. **Unified memory** — MLX tensors share memory with Swift, no copies
4. **ChatSession** — built-in conversation state management (system prompt, history, streaming)
5. **Model hub** — `#huggingFaceLoadModelContainer` macro for one-line model loading
6. **Apple-first** — maintained by Apple's MLX team, optimized for A18/M4

**Model format:** MLX uses safetensors (standard HuggingFace format). Models are quantized to 4-bit using MLX's built-in quantization. The `mlx-community` on HuggingFace provides pre-quantized MLX models for popular architectures.

---

## 3. Data Flow

### 3.1 Chat Message Flow

```
User types message
  → ChatViewModel.sendMessage(text)
    → Build conversation messages (system prompt + history + new user message)
    → ModelManager.ensureTextModelLoaded()
      → InferenceEngine.generate(prompt, maxTokens: 2048)
        → MLXLLM ChatSession.generate()
          → AsyncThrowingStream<String, Error>
            → ChatViewModel accumulates tokens
              → ChatView renders streaming Markdown
    → Save to SwiftData (ChatMessage)
```

### 3.2 Vision Flow

```
User selects/captures image
  → VisionView triggers VisionService.analyze(image, prompt)
    → preprocessImage(resize to 1024px max)
    → ModelManager.unloadCurrentModel()
    → ModelManager.ensureVisionModelLoaded()
    → InferenceEngine.generateVision(image, prompt)
      → MLXVLM model generate with image input
    → Return streaming response
    → Optionally reload text model after
```

### 3.3 Model Import Flow

```
USB drive connected
  → USBImportService.detectDrive()
    → Scan for model directories (safetensors + config.json)
    → Display available models in ModelImportView
    → User taps "Import"
    → Copy to Documents/Models/<model-name>/
    → ModelManager discovers new model
    → Ready to load
```

---

## 4. Memory Management Strategy

### 4.1 Budget

| Component | Budget |
|-----------|--------|
| iOS + system | ~2.5 GB |
| App (UI, SwiftData, buffers) | ~0.5 GB |
| **Available for models** | **~5.0 GB** |
| **Safety ceiling** | **5.5 GB** |

### 4.2 Rules

1. **One model at a time** — never load text + vision simultaneously
2. **Before loading:** check `MemoryMonitor.pressureLevel` — if `.warning` or `.critical`, refuse and notify user
3. **During inference:** monitor `MemoryMonitor` — if pressure spikes to `.critical`, cancel generation and unload
4. **Idle timeout:** Model unloaded after 5 minutes of inactivity (configurable)
5. **Thermal gate:** If `ThermalMonitor.state >= .serious`, pause inference, show cooling message
6. **Background:** Unload model when app enters background, reload on foreground if needed

### 4.3 Model Lifecycle

```
App Launch → discoverModels() → show "No model" state
     ↓
User imports model → ModelManager discovers it
     ↓
First chat → ensureTextModelLoaded() → load phi-4-mini
     ↓
Chat session → keep loaded (streaming, responsive)
     ↓
Idle 5 min → unloadModel()
     ↓
Vision request → unload text → load smolvlm2 → run → unload vision → reload text
```

---

## 5. Concurrency Model

- **ViewModels:** `@MainActor` `@Observable` classes — all UI state on main actor
- **Services:** `actor` types — serial execution, no data races
- **Inference:** MLX Swift runs on GPU (Metal command queues), async from Swift
- **Streaming:** `AsyncThrowingStream<String, Error>` — non-blocking, cancellable, Swift concurrency native
- **No locks:** Swift actors + structured concurrency eliminate need for manual locking

---

## 6. Project Structure (v1)

```
ALIVE_APPLE/
├── ALIVE_APPLEApp.swift              # App entry, environment setup
├── ContentView.swift                 # Tab view root
├── Models/
│   ├── ModelConfig.swift             # Text + vision model definitions
│   └── ChatMessage.swift             # SwiftData chat model
├── Services/
│   ├── InferenceEngine.swift         # MLX Swift wrapper (actor)
│   ├── ModelManager.swift            # Model lifecycle (actor)
│   ├── VisionService.swift           # Image processing + VLM dispatch (actor)
│   ├── USBImportService.swift        # USB detection + import (actor)
│   ├── ServiceContainer.swift        # Shared service instances
│   └── SystemPrompt.swift            # ALIVE on-device persona
├── Views/
│   ├── ChatView.swift                # Streaming chat UI
│   ├── VisionView.swift              # Photo/camera + analysis
│   ├── ModelImportView.swift         # USB import workflow
│   └── SettingsView.swift            # Preferences + system info
├── ViewModels/
│   ├── ChatViewModel.swift           # Chat state + streaming
│   ├── ModelViewModel.swift          # Model status + import
│   └── SettingsViewModel.swift       # Preferences
├── Utils/
│   ├── MemoryMonitor.swift           # Memory pressure observer
│   ├── ThermalMonitor.swift          # Thermal state observer
│   └── DesignTokens.swift            # Colors, spacing, typography
└── Tests/
    └── ALIVE_APPLETests.swift
```

---

*Architecture optimized for reliability, not feature count. One model, done well.*
