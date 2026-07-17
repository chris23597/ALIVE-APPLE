# ALIVE APPLE — Step-by-Step Build Guide

**Version:** 1.0.0  
**Required:** macOS 15+ (Sequoia), Xcode 17+, iPhone 16 (A18, 8GB)  
**Language:** Swift 6  
**Framework:** SwiftUI, iOS 18+  

---

## 0. Quick Start — No Mac? Read this first

**iOS apps MUST be built on a Mac.** You have two paths:

### Path A: You have a Mac (or can borrow one) — 30 minutes
1. Clone this repo to the Mac
2. Open Xcode 17 → New Project → iOS App → "ALIVE APPLE"
3. Drag all `.swift` files from `ALIVE_APPLE/` into the project
4. Plug in your iPhone 16 via USB-C
5. Press Cmd+R — app installs and launches

### Path B: You DON'T have a Mac — here are your options
| Option | Cost | Time |
|--------|------|------|
| **Borrow a friend's Mac** | Free | 30 min |
| **MacStadium** (cloud Mac) | ~$20/month | 1-2 hours setup |
| **MacinCloud** (rented Mac) | ~$25/month | 1-2 hours setup |
| **Buy Mac Mini M4** | $599 one-time | 1 hour |

Once the app is installed on your iPhone, you don't need the Mac again. The app runs fully offline — all inference happens on the A18 chip.

### What's already done (no Mac needed for this part):
- All Swift source code is written and in `ALIVE_APPLE/`
- All 4 GGUF models are downloaded to your USB flash drive (D:\)
- Flash drive is exFAT formatted — iPhone 16 reads it natively
- Just needs a Mac to compile and sign the app

---

## 1. Prerequisites

### 1.1 Hardware
- Mac with Apple Silicon (M1+) running macOS 15 Sequoia
- iPhone 16 with iOS 18+ (for on-device testing)
- USB-C flash drive (256GB, formatted exFAT)

### 1.2 Software
- Xcode 17 (from Mac App Store)
- Command Line Tools: `xcode-select --install`
- Homebrew (for additional tools)
- Python 3.11+ (for model conversion scripts)
- Git

### 1.3 Accounts
- Apple Developer account ($99/year for device deployment)
- xAI account (for Grok API key, optional)

---

## 2. Project Setup

### 2.1 Clone & Structure

```bash
# Create project root
mkdir -p ~/Projects/ALIVE_APPLE
cd ~/Projects/ALIVE_APPLE

# The project follows this exact structure:
# ALIVE_APPLE/
# ├── ALIVE_APPLE.xcodeproj/
# ├── ALIVE_APPLE/           <-- Swift source
# │   ├── Models/
# │   ├── Services/
# │   ├── Views/
# │   ├── ViewModels/
# │   └── Utils/
# ├── Docs/
# ├── Scripts/
# └── *.md
```

### 2.2 Create Xcode Project

1. Open Xcode 17
2. **File → New → Project**
3. Template: **iOS → App**
4. Configure:
   - Product Name: `ALIVE APPLE`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.aliveapple`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 18.0**
   - Storage: **SwiftData** (for chat history)
5. Save to `~/Projects/ALIVE_APPLE/`

### 2.3 Info.plist Configuration

Add to `ALIVE_APPLE/Info.plist`:

```xml
<!-- Speech Recognition -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>ALIVE APPLE uses speech recognition to transcribe your voice prompts. All processing is on-device.</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>ALIVE APPLE needs microphone access for voice input and chat mode.</string>

<!-- Camera (for Vision) -->
<key>NSCameraUsageDescription</key>
<string>ALIVE APPLE uses the camera for visual AI analysis. Images are processed on-device.</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>ALIVE APPLE can analyze photos from your library using on-device AI.</string>

<!-- File Access (USB import) -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

<!-- Background Modes (optional) -->
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

---

## 3. Dependency Setup

### 3.1 Swift Package Manager Dependencies

Add via Xcode: **File → Add Package Dependencies**

| Package | URL | Version | Purpose |
|---------|-----|---------|---------|
| llama.cpp (Swift) | `https://github.com/ggerganov/llama.cpp` | Latest | GGUF inference |
| MLX Swift | `https://github.com/ml-explore/mlx-swift` | Latest | MLX model inference |
| Swift Markdown | `https://github.com/apple/swift-markdown` | Latest | Markdown rendering |

**llama.cpp integration (manual):**

```bash
cd ~/Projects/ALIVE_APPLE
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
# Build for iOS
mkdir build-ios && cd build-ios
cmake .. -DCMAKE_SYSTEM_NAME=iOS \
         -DCMAKE_OSX_ARCHITECTURES=arm64 \
         -DCMAKE_OSX_DEPLOYMENT_TARGET=18.0 \
         -DLLAMA_METAL=ON \
         -DBUILD_SHARED_LIBS=OFF
cmake --build . --config Release -j$(sysctl -n hw.ncpu)
# This produces libllama.a for static linking
```

### 3.2 CoreML Model Preparation

For embedding model and optional Whisper:

```bash
cd ~/Projects/ALIVE_APPLE/Scripts

# Convert sentence-transformers model to CoreML
python3 convert_to_coreml.py \
    --model sentence-transformers/all-MiniLM-L6-v2 \
    --output ../ALIVE_APPLE/Resources/all-MiniLM-L6-v2.mlmodelc

# Optional: Convert Whisper
python3 convert_to_coreml.py \
    --model openai/whisper-small \
    --output ../ALIVE_APPLE/Resources/whisper-small.mlmodelc
```

---

## 4. Building the App

### 4.1 Source Files

Copy all Swift files from this project into your Xcode project:

```
ALIVE_APPLE/
├── ALIVE_APPLEApp.swift          ← App entry point
├── ContentView.swift             ← Root tab view
├── Models/
│   ├── ChatMessage.swift
│   ├── ModelConfig.swift
│   ├── RoutingTier.swift
│   └── AppState.swift
├── Services/
│   ├── InferenceEngine.swift
│   ├── ModelManager.swift
│   ├── AutoRouter.swift
│   ├── VoiceService.swift
│   ├── VisionService.swift
│   ├── RAGService.swift
│   ├── KeychainManager.swift
│   └── USBImportService.swift
├── Views/
│   ├── DashboardView.swift
│   ├── ChatView.swift
│   ├── ModelPickerView.swift
│   ├── SettingsView.swift
│   ├── VisionView.swift
│   └── ModelImportView.swift
├── ViewModels/
│   ├── ChatViewModel.swift
│   ├── SettingsViewModel.swift
│   └── ModelViewModel.swift
└── Utils/
    ├── ThermalMonitor.swift
    └── MemoryMonitor.swift
```

### 4.2 Build Configuration

In Xcode, set:

| Setting | Value |
|---------|-------|
| **Swift Language Version** | Swift 6 |
| **Optimization Level (Release)** | `-Osize` |
| **Metal Compiler** | Default (Metal 3.2) |
| **Deployment Target** | iOS 18.0 |
| **Architectures** | arm64 (iPhone 16) |
| **Dead Code Stripping** | Yes |
| **Strip Swift Symbols** | Yes |
| **Enable Bitcode** | No |

### 4.3 Build & Run

```bash
# Command line build
xcodebuild -project ALIVE_APPLE.xcodeproj \
           -scheme "ALIVE APPLE" \
           -configuration Release \
           -destination 'platform=iOS,id=<YOUR_DEVICE_UDID>' \
           build

# Or: Product → Run (⌘R) in Xcode
```

---

## 5. Model Preparation

### 5.1 Download Models to USB Drive

```bash
cd ~/Projects/ALIVE_APPLE/Scripts

# Edit USB mount path in download_models.sh, then:
bash download_models.sh

# This downloads all Q4_K_M GGUF files to:
# /Volumes/ALIVE_MODELS/
```

### 5.2 Verify Downloads

```bash
ls -lh /Volumes/ALIVE_MODELS/
# Expected:
# Phi-4-mini-instruct-Q4_K_M.gguf      ~2.4 GB
# qwen2.5-7b-instruct-Q4_K_M.gguf      ~4.4 GB
# SmolVLM2-2.2B-Instruct-Q4_K_M.gguf   ~1.4 GB
# qwen2.5-vl-7b-instruct-Q4_K_M.gguf   ~4.7 GB
```

### 5.3 SHA-256 Validation

```bash
shasum -a 256 /Volumes/ALIVE_MODELS/*.gguf > /Volumes/ALIVE_MODELS/checksums.sha256
# Compare with known-good hashes from MODEL_INVENTORY.md
```

### 5.4 Import to iPhone

1. Plug USB-C drive into iPhone 16
2. Open Files app → navigate to USB drive
3. Select all .gguf files → Share → "ALIVE APPLE"
4. Or: Launch ALIVE APPLE → Models → Import from USB

---

## 6. First Launch Flow

1. Launch ALIVE APPLE
2. App detects no models → shows import screen
3. User imports from USB or taps "Download Models"
4. After import, Fast tier loads automatically (Phi-4 Mini 3.8B)
5. Dashboard shows "Fast 🟢 Ready"
6. User can start chatting immediately

---

## 7. Development Workflow

### 7.1 Simulator Limitations

- No Metal GPU access → llama.cpp runs on CPU (slow)
- No Neural Engine → CoreML runs on CPU
- No USB-C → can't test USB import
- **Recommendation:** Develop UI on simulator, test inference on device

### 7.2 Device Testing

1. Connect iPhone 16 via USB-C
2. Trust the computer on iPhone
3. In Xcode: select iPhone 16 as destination
4. Build & Run (⌘R)
5. For release testing: Product → Archive → Distribute via TestFlight

### 7.3 Debugging Inference

```swift
// Enable verbose logging in debug builds
#if DEBUG
let llamaLogLevel = GGML_LOG_LEVEL_DEBUG
#endif
```

Check Xcode console for:
- Model load time
- Token generation speed (tok/s)
- Memory pressure warnings
- Thermal state changes

---

## 8. Performance Tuning

### 8.1 Context Window

Default context sizes (adjust for memory):

```swift
// In ModelManager
static let contextSizes: [RoutingTier: Int] = [
    .fast: 4096,     // Phi-4 Mini: keep small for speed
    .moderate: 8192, // Qwen2.5 7B: moderate context
    .pro: 16384      // Grok API: generous
]
```

### 8.2 Batch Size

```swift
// llama.cpp batch size
let nBatch = 512  // Tokens per batch — balance speed vs memory
```

### 8.3 GPU Layers

```swift
// Offload to GPU
let nGpuLayers = 33  // All layers to Metal GPU on A18
```

---

## 9. Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **"Model fails to load"** | Check file is valid GGUF: `python3 -c "from gguf import GGUFReader; r=GGUFReader('model.gguf'); print('OK')"` |
| **"App killed by iOS"** | Reduce model size or context window. Check memory pressure logs. |
| **"Slow inference"** | Ensure Metal GPU layers are enabled. Check thermal state — throttling? |
| **"No models detected on USB"** | Ensure USB is exFAT. Verify file extensions (.gguf). |
| **"API key not working"** | Validate at console.x.ai. Check internet connection. |
| **"Build fails for llama.cpp"** | Check iOS deployment target matches. Clean build folder. |
| **"Speech recognition not working"** | Check permissions in Settings → Privacy. Ensure Siri is enabled. |

---

## 10. Production Checklist

Before App Store submission:

- [ ] All models validated (SHA-256)
- [ ] Fast tier loads in <2s
- [ ] Moderate tier loads in <5s
- [ ] Vision analysis completes <5s
- [ ] Voice input works offline
- [ ] Pro tier falls back gracefully when offline
- [ ] Memory never exceeds 7GB
- [ ] No thermal throttling during 10-min stress test
- [ ] Dark mode renders correctly
- [ ] Dynamic Type works (all sizes)
- [ ] VoiceOver labels present
- [ ] Privacy manifest included
- [ ] No 3rd-party analytics
- [ ] App thinning enabled
- [ ] TestFlight beta tested on 5+ iPhone 16 devices

---

*Build time estimate: ~2 hours setup + model downloads (depends on bandwidth).  
First build with llama.cpp takes ~15 minutes (full C++ compilation).  
Incremental Swift builds: ~30 seconds.*
