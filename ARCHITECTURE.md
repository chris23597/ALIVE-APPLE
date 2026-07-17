# ALIVE APPLE — System Architecture

**Version:** 1.0.0  
**Target:** iPhone 16 (A18, 8GB RAM) + USB-C exFAT storage  

---

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │Dashboard │ │  Chat    │ │  Vision  │ │ Settings │           │
│  │   View   │ │  View    │ │  View    │ │  View    │           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │             │            │            │                  │
│  ┌────┴─────────────┴────────────┴────────────┴─────┐           │
│  │              ViewModels (ObservableObject)        │           │
│  │  ChatVM  │  SettingsVM  │  ModelVM  │  VisionVM  │           │
│  └──────────────────────┬───────────────────────────┘           │
├─────────────────────────┼───────────────────────────────────────┤
│                    BUSINESS LOGIC LAYER                          │
│  ┌──────────────────────┴───────────────────────────┐           │
│  │          Service Actors (global actors)           │           │
│  │                                                  │           │
│  │  ┌──────────────┐  ┌──────────────┐              │           │
│  │  │InferenceEngine│  │ ModelManager │              │           │
│  │  │   (Actor)    │  │   (Actor)    │              │           │
│  │  └──────┬───────┘  └──────┬───────┘              │           │
│  │         │                 │                       │           │
│  │  ┌──────┴───────┐  ┌─────┴────────┐              │           │
│  │  │ AutoRouter   │  │VoiceService  │              │           │
│  │  │   (Actor)    │  │   (Actor)    │              │           │
│  │  └──────────────┘  └──────────────┘              │           │
│  │                                                  │           │
│  │  ┌──────────────┐  ┌──────────────┐              │           │
│  │  │VisionService │  │ RAGService   │              │           │
│  │  │   (Actor)    │  │   (Actor)    │              │           │
│  │  └──────────────┘  └──────────────┘              │           │
│  │                                                  │           │
│  │  ┌──────────────┐  ┌──────────────┐              │           │
│  │  │KeychainMgr   │  │USBImportSvc  │              │           │
│  │  │   (Actor)    │  │   (Actor)    │              │           │
│  │  └──────────────┘  └──────────────┘              │           │
│  └──────────────────────┬───────────────────────────┘           │
├─────────────────────────┼───────────────────────────────────────┤
│                    INFERENCE BACKENDS                            │
│  ┌──────────────────────┴───────────────────────────┐           │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │           │
│  │  │ llama.cpp│  │ MLX Swift│  │ CoreML   │       │           │
│  │  │ (GGUF)   │  │ (MLX)    │  │ (ANE)    │       │           │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘       │           │
│  │       │             │            │               │           │
│  │  ┌────┴─────────────┴────────────┴─────┐         │           │
│  │  │       Model File Store              │         │           │
│  │  │  ~/Library/ALIVE_APPLE/Models/      │         │           │
│  │  └─────────────────────────────────────┘         │           │
│  └──────────────────────────────────────────────────┘           │
├──────────────────────────────────────────────────────────────────┤
│                   APPLE SILICON (A18)                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │CPU Cores │  │GPU Cores │  │Neural Eng│  │ 8GB RAM  │        │
│  │  (6)     │  │   (5)    │  │  (16)    │  │ LPDDR5   │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Details

### 2.1 Presentation Layer (SwiftUI)

All views are pure SwiftUI, following MVVM. ViewModels are `@Observable` (iOS 17+) classes that hold `@MainActor` state. Views never access services directly.

**Key Views:**
| View | Purpose |
|------|---------|
| `DashboardView` | Landing screen — tier indicator, quick-prompt bar, model status, memory/thermal gauges |
| `ChatView` | Full chat interface with streaming, markdown, image display |
| `VisionView` | Camera capture + photo picker + VLM analysis results |
| `SettingsView` | API key, model management, preferences |
| `ModelPickerView` | Tier selection (Fast/Moderate/Pro/None) |
| `ModelImportView` | USB/Files import workflow |

### 2.2 Business Logic Layer (Swift Actors)

All services are `actor` types for thread safety. They communicate with ViewModels via async methods.

**Key Services:**

#### `InferenceEngine` (Actor)
- Primary interface for text generation
- Manages llama.cpp / MLX inference sessions
- Streaming token callback via `AsyncStream`
- Handles context management, prompt templating
- Timeout enforcement

#### `ModelManager` (Actor)
- Model lifecycle: load, unload, reload
- RAM budget tracking
- Model file discovery and validation
- Keeps only active-tier models in memory
- Reports model status to ViewModels

#### `AutoRouter` (Actor)
- Analyzes incoming prompts for complexity
- Considers: keyword density, embedding similarity to known-hard queries, message length
- Reads system state: RAM pressure, battery, thermal
- Selects tier: Fast | Moderate | Pro (if online)
- Returns routing decision with confidence score

#### `VoiceService` (Actor)
- On-device STT via Apple Speech framework (or Whisper CoreML)
- TTS via AVSpeechSynthesizer
- Voice Activity Detection (VAD) for continuous listening
- Audio session management

#### `VisionService` (Actor)
- Camera capture via AVFoundation
- Photo library access via PHPicker
- Image preprocessing (resize to model input dimensions)
- VLM inference dispatch
- Result parsing

#### `RAGService` (Actor)
- Document ingestion (PDF, TXT, MD)
- On-device embedding generation (all-MiniLM-L6-v2 CoreML)
- Vector similarity search (Swift-native ANN)
- Context window assembly

#### `KeychainManager` (Actor)
- Secure API key storage/retrieval
- Key presence check
- Deletion

#### `USBImportService` (Actor)
- Monitor for USB-C drive mounting
- Scan for GGUF/MLX/CoreML model files
- Validate model format and size
- Copy to app-local model store
- exFAT compatibility verification

### 2.3 Inference Backends

| Backend | Format | Use Case | Notes |
|---------|--------|----------|-------|
| **llama.cpp** (via Swift bindings) | GGUF Q4_K_M | Primary text LLM backend | Best GGUF support, Metal acceleration |
| **MLX Swift** | MLX (safetensors) | Alternative text/VLM backend | Apple-first, growing ecosystem |
| **CoreML** (ANE) | .mlmodelc | Embeddings, Whisper, SmolVLM | Fastest on ANE, size limited |

**Backend Selection Logic:**
1. Prefer CoreML for small models (<1GB) that fit ANE
2. Prefer llama.cpp for GGUF models (>1GB)
3. MLX Swift as fallback / future path

---

## 3. Data Flow

### 3.1 Chat Message Flow

```
User types message
  → ChatViewModel.sendMessage(text)
    → AutoRouter.route(text, systemState) → tier decision
      → if Fast/Moderate:
          → ModelManager.ensureLoaded(tier)
          → InferenceEngine.generate(prompt, model, stream)
            → AsyncStream<String> → ChatViewModel.appendToken
      → if Pro:
          → GrokAPIService.send(prompt, apiKey)
            → AsyncStream<String> → ChatViewModel.appendToken
```

### 3.2 Vision Flow

```
User captures/selects image
  → VisionService.analyze(image, prompt)
    → Preprocess image (resize, normalize)
    → AutoRouter.routeForVision(image, prompt) → VLM tier
    → ModelManager.ensureVLMLoaded(tier)
    → InferenceEngine.generateVision(image + prompt, vlm)
    → Parsed result → VisionView.display()
```

### 3.3 Model Import Flow

```
USB drive connected
  → USBImportService.detectDrive()
    → Scan for model files (*.gguf, *.mlx, *.mlmodelc)
    → Validate format + metadata
    → Show available models in UI
    → User confirms import
    → Copy to ~/Library/ALIVE_APPLE/Models/
    → ModelManager.register(new models)
```

---

## 4. State Management

### 4.1 App State (`AppState` — `@Observable`)
```swift
@Observable
final class AppState {
    var activeTier: RoutingTier = .fast
    var isOnline: Bool = false
    var memoryPressure: MemoryPressure = .normal
    var thermalState: ThermalState = .nominal
    var batteryLevel: Float = 1.0
    var loadedModels: [ModelConfig] = []
    var hasAPIKey: Bool = false
}
```

### 4.2 Chat State (`ChatViewModel` — `@Observable`)
```swift
@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var currentStreamingMessage: String = ""
    var isGenerating: Bool = false
    var currentTier: RoutingTier = .fast
}
```

---

## 5. Performance Budget

| Metric | Budget |
|--------|--------|
| Total RAM | 8GB |
| iOS + system reserve | 2.5GB |
| Model RAM ceiling | 5.5GB |
| Fast tier models loaded | ~3.8GB (Phi-4 Mini + SmolVLM2) |
| Moderate tier loaded | ~5.1GB (Qwen2.5 7B + Qwen2.5-VL 7B) — tight but fits |
| Max concurrent models | 2 (1 text + 1 vision) |
| Streaming token latency | <50ms between tokens |
| Vision preprocessing | <200ms |
| Model swap time | <3 seconds |

---

## 6. Security Model

| Concern | Solution |
|---------|----------|
| API key storage | iOS Keychain (kSecClassGenericPassword) |
| Chat history | App sandbox only (no iCloud) |
| Model files | App sandbox only |
| Network (Pro tier only) | HTTPS, ATS-compliant |
| No telemetry | No 3rd-party analytics SDKs |
| Code signing | Standard Apple Developer cert |

---

## 7. Directory Structure

```
ALIVE_APPLE/
├── PRD.md
├── ARCHITECTURE.md
├── BUILD_GUIDE.md
├── MODEL_INVENTORY.md
├── TESTING_PLAN.md
├── USB_SETUP.md
├── README.md
├── Docs/
│   ├── ROUTING.md
│   ├── VOICE.md
│   ├── API_KEY.md
│   └── UI_MOCKUPS.md
├── ALIVE_APPLE.xcodeproj/
├── ALIVE_APPLE/
│   ├── ALIVE_APPLEApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── ChatMessage.swift
│   │   ├── ModelConfig.swift
│   │   ├── RoutingTier.swift
│   │   └── AppState.swift
│   ├── Services/
│   │   ├── InferenceEngine.swift
│   │   ├── ModelManager.swift
│   │   ├── AutoRouter.swift
│   │   ├── VoiceService.swift
│   │   ├── VisionService.swift
│   │   ├── RAGService.swift
│   │   ├── KeychainManager.swift
│   │   └── USBImportService.swift
│   ├── Views/
│   │   ├── DashboardView.swift
│   │   ├── ChatView.swift
│   │   ├── ModelPickerView.swift
│   │   ├── SettingsView.swift
│   │   ├── VisionView.swift
│   │   └── ModelImportView.swift
│   ├── ViewModels/
│   │   ├── ChatViewModel.swift
│   │   ├── SettingsViewModel.swift
│   │   └── ModelViewModel.swift
│   └── Utils/
│       ├── ThermalMonitor.swift
│       └── MemoryMonitor.swift
└── Scripts/
    ├── download_models.sh
    └── convert_to_coreml.py
```

---

## 8. Dependency Map

```
ALIVE_APPLEApp
  └─> AppState (global Observable)
       └─> ContentView
            ├─> DashboardView
            │    └─> ModelViewModel → ModelManager
            ├─> ChatView
            │    └─> ChatViewModel → InferenceEngine, AutoRouter
            ├─> VisionView
            │    └─> VisionViewModel → VisionService, InferenceEngine
            ├─> SettingsView
            │    └─> SettingsViewModel → KeychainManager, ModelManager
            └─> ModelImportView
                 └─> USBImportService
```

---

*This architecture is designed for iPhone 16 on-device performance.  
It respects 8GB RAM, A18 thermal constraints, and Apple's iOS sandbox model.*
