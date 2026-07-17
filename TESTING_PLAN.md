# ALIVE APPLE — Testing Plan

**Version:** 1.0.0  

---

## 1. Test Strategy

### Testing Pyramid

```
       ┌─────────┐
       │  E2E    │  5%  — Critical user journeys (manual on device)
       │   UI    │
       ├─────────┤
       │  Manual │  15% — Visual, voice, thermal (device only)
       │ Device  │
       ├─────────┤
       │  UI     │  30% — ViewModel + Service integration (XCTest)
       │  Tests  │
       ├─────────┤
       │  Unit   │  50% — Models, routing logic, services (Swift Testing)
       │  Tests  │
       └─────────┘
```

---

## 2. Unit Tests

### 2.1 AutoRouter Tests

```swift
import Testing
@testable import ALIVE_APPLE

struct AutoRouterTests {
    
    @Test("Simple greeting routes to Fast tier")
    func simpleGreetingToFast() async {
        let router = AutoRouter()
        let inputs = RoutingInputs(
            prompt: "Hello!",
            hasImage: false,
            conversationLength: 1,
            memoryPressure: .normal,
            thermalState: .nominal,
            batteryLevel: 0.8,
            isOnline: false,
            hasAPIKey: false,
            forcedTier: nil
        )
        let decision = await router.route(inputs: inputs)
        #expect(decision.tier == .fast)
    }
    
    @Test("Complex reasoning routes to Moderate")
    func complexReasoningToModerate() async {
        let router = AutoRouter()
        let inputs = RoutingInputs(
            prompt: "Please explain in detail how quantum entanglement works and compare it with classical correlation, step by step.",
            hasImage: false,
            conversationLength: 1,
            memoryPressure: .normal,
            thermalState: .nominal,
            batteryLevel: 0.8,
            isOnline: false,
            hasAPIKey: false,
            forcedTier: nil
        )
        let decision = await router.route(inputs: inputs)
        #expect(decision.tier == .moderate)
    }
    
    @Test("Thermal critical forces Fast tier")
    func thermalCriticalForcesFast() async {
        let router = AutoRouter()
        let inputs = RoutingInputs(
            prompt: "Explain quantum mechanics in depth...",
            hasImage: false,
            conversationLength: 1,
            memoryPressure: .normal,
            thermalState: .critical,
            batteryLevel: 0.8,
            isOnline: false,
            hasAPIKey: false,
            forcedTier: nil
        )
        let decision = await router.route(inputs: inputs)
        #expect(decision.tier == .fast)
    }
    
    @Test("User override respected")
    func userOverrideWins() async {
        let router = AutoRouter()
        let inputs = RoutingInputs(
            prompt: "Hello!",
            hasImage: false,
            conversationLength: 1,
            memoryPressure: .normal,
            thermalState: .nominal,
            batteryLevel: 0.8,
            isOnline: false,
            hasAPIKey: false,
            forcedTier: .pro
        )
        let decision = await router.route(inputs: inputs)
        #expect(decision.tier == .pro)
    }
    
    @Test("Pro tier selected when online with API key for complex task")
    func proTierSelectedForComplexWhenOnline() async {
        let router = AutoRouter()
        let inputs = RoutingInputs(
            prompt: "Design a complete architecture for a distributed database system with detailed trade-offs...",
            hasImage: false,
            conversationLength: 35,
            memoryPressure: .normal,
            thermalState: .nominal,
            batteryLevel: 0.8,
            isOnline: true,
            hasAPIKey: true,
            forcedTier: nil
        )
        let decision = await router.route(inputs: inputs)
        #expect(decision.tier == .pro)
    }
    
    @Test("Low battery forces Fast tier")
    func lowBatteryForcesFast() async {
        let router = AutoRouter()
        let inputs = RoutingInputs(
            prompt: "Explain complex math...",
            hasImage: false,
            conversationLength: 1,
            memoryPressure: .normal,
            thermalState: .nominal,
            batteryLevel: 0.05,
            isOnline: false,
            hasAPIKey: false,
            forcedTier: nil
        )
        let decision = await router.route(inputs: inputs)
        #expect(decision.tier == .fast)
    }
    
    @Test("Complexity scoring: code detection")
    func complexityScoreCodeDetection() {
        let router = AutoRouter()
        let score = router.complexityScore(
            prompt: "Can you write a function in Swift that implements a binary search tree with insertion and deletion?",
            conversationLength: 1
        )
        #expect(score > 0.3) // Code keywords bump score
    }
    
    @Test("Complexity scoring: simple greeting is low")
    func complexityScoreSimpleGreeting() {
        let router = AutoRouter()
        let score = router.complexityScore(
            prompt: "Hi there!",
            conversationLength: 1
        )
        #expect(score < 0.3)
    }
}
```

### 2.2 ModelManager Tests

```swift
@Test("Model validation rejects wrong file extension")
func rejectsWrongExtension() {
    let manager = ModelManager()
    let result = manager.validateModelFile(url: URL(string: "file://model.bin")!)
    #expect(result == false)
}

@Test("Model validation accepts GGUF")
func acceptsGGUF() {
    let manager = ModelManager()
    let result = manager.validateModelFile(url: URL(string: "file://model.gguf")!)
    #expect(result == true)
}

@Test("Memory budget respects ceiling")
func respectsMemoryBudget() async {
    let manager = ModelManager(memoryBudgetGB: 5.5)
    // Attempt to load a 6GB model
    let result = await manager.canLoadModel(sizeGB: 6.0)
    #expect(result == false)
}

@Test("Can load model within budget")
func canLoadWithinBudget() async {
    let manager = ModelManager(memoryBudgetGB: 5.5)
    let result = await manager.canLoadModel(sizeGB: 2.4)
    #expect(result == true)
}
```

### 2.3 KeychainManager Tests

```swift
@Test("Save and read key")
func saveAndReadKey() async throws {
    let manager = KeychainManager()
    try await manager.saveKey("test-key-12345")
    let key = try await manager.readKey()
    #expect(key == "test-key-12345")
    try await manager.deleteKey()
}

@Test("Has key returns correct state")
func hasKeyState() async throws {
    let manager = KeychainManager()
    try await manager.deleteKey() // ensure clean state
    #expect(await manager.hasKey() == false)
    try await manager.saveKey("test")
    #expect(await manager.hasKey() == true)
    try await manager.deleteKey()
}
```

---

## 3. Integration Tests

### 3.1 Chat Flow

```swift
@Test("Full chat flow with Fast tier", .enabled(if: modelsAvailable()))
func fullChatFlowFast() async throws {
    let viewModel = await ChatViewModel()
    
    // Load model
    try await viewModel.loadModel(tier: .fast)
    
    // Send message
    await viewModel.sendMessage("What is 2+2?")
    
    // Wait for response
    try await Task.sleep(for: .seconds(5))
    
    #expect(!viewModel.messages.isEmpty)
    #expect(viewModel.messages.last?.role == .assistant)
    #expect(viewModel.currentTier == .fast)
}

@Test("Vision analysis with Fast VLM", .enabled(if: modelsAvailable()))
func visionAnalysisFast() async throws {
    let service = VisionService()
    let testImage = UIImage(named: "test_plant")!
    
    let result = try await service.analyze(image: testImage, prompt: "What is this?")
    
    #expect(!result.isEmpty)
    #expect(result.count > 10) // At least some text
}
```

### 3.2 Routing Integration

```swift
@Test("Router integrates with ChatViewModel")
func routerIntegration() async {
    let viewModel = await ChatViewModel()
    
    // Complex prompt should route to moderate (if available)
    let complexPrompt = "Explain the theory of relativity in detail and compare it with Newtonian physics"
    
    await viewModel.sendMessage(complexPrompt)
    
    // Check routing decision was made
    let messages = await viewModel.messages
    #expect(messages.count >= 1) // User message added
}
```

---

## 4. Device-Only Tests (Manual)

### 4.1 USB Import Test

| Step | Expected |
|------|----------|
| 1. Format USB as exFAT with model files | USB detected in Files app |
| 2. Plug USB into iPhone 16 | ALIVE APPLE detects drive |
| 3. Tap "Import" on Phi-4 Mini | Import progress bar fills |
| 4. Check model list | Phi-4 Mini appears as "Ready" |
| 5. Unplug USB | App continues working normally |
| 6. Plug USB with corrupted file | App shows validation error |

### 4.2 Thermal Test

| Step | Expected |
|------|----------|
| 1. Run 10 consecutive Moderate-tier inferences | Device warms up |
| 2. Monitor thermal state | Transitions to `.fair` then `.serious` |
| 3. At `.serious`, start new inference | Auto-routed to Fast tier |
| 4. Toast appears | "Switched to Fast — device cooling" |
| 5. Wait 5 minutes | Thermal returns to `.nominal` |
| 6. New inference | Moderate tier available again |

### 4.3 Offline Test

| Step | Expected |
|------|----------|
| 1. Enable Airplane mode | App shows "Offline" indicator |
| 2. Try Pro tier | "Requires internet" modal. Offers Moderate. |
| 3. Chat with Fast tier | Works normally |
| 4. Vision analysis with Fast VLM | Works normally |
| 5. Voice input | Works (on-device Speech framework) |

### 4.4 Voice Chat Test

| Step | Expected |
|------|----------|
| 1. Tap mic button | Recording animation starts |
| 2. Speak "Hello, how are you?" | Text appears after 1.5s silence |
| 3. Response streams in | Text appears, TTS speaks |
| 4. Tap mic again | Voice chat ends |

### 4.5 Grok API Test

| Step | Expected |
|------|----------|
| 1. Settings → Pro Tier → Add Key | Paste key → "Validating..." → "✅ Connected" |
| 2. Switch to Pro tier | Tier badge shows blue Pro |
| 3. Send message | Response returns in ~2s |
| 4. Remove key from Settings | Pro tier shows "No API key" |
| 5. Delete key | Pro tier unavailable |

### 4.6 Memory Pressure Test

| Step | Expected |
|------|----------|
| 1. Load Moderate tier (4.4GB) | RAM gauge shows ~5GB used |
| 2. Load Vision model too | Warning: "Memory low — unload one model?" |
| 3. Decline warning | Keep both loaded |
| 4. iOS memory pressure | Models auto-unloaded by system |
| 5. App shows "Models unloaded — tap to reload" |

---

## 5. Performance Benchmarks

| Test | Target | Threshold |
|------|--------|-----------|
| Fast tier token generation | 15-25 tok/s | >10 tok/s |
| Moderate tier token generation | 8-12 tok/s | >5 tok/s |
| Model load (Fast) | <2 seconds | <3 seconds |
| Model load (Moderate) | <3 seconds | <5 seconds |
| Vision analysis (Fast VLM) | <3 seconds | <5 seconds |
| Vision analysis (Moderate VLM) | <5 seconds | <8 seconds |
| UI responsiveness during inference | 60 FPS | No frame drops |
| App cold start | <1 second | <2 seconds |
| App warm start | Instant | <0.5 seconds |
| Memory at idle | <300 MB | <500 MB |
| Memory fast loaded | <3.5 GB | <4 GB |
| Memory moderate loaded | <5.5 GB | <6 GB |

---

## 6. Test Data

### 6.1 Test Prompts

```
Fast tier:
- "What is the capital of France?"
- "Summarize: The mitochondrion is the powerhouse of the cell."
- "Write a haiku about coding."

Moderate tier:
- "Explain the differences between REST and GraphQL in detail."
- "Write a Python function that solves the traveling salesman problem using dynamic programming."
- "Compare and contrast Keynesian and Austrian economics."

Pro tier:
- "Design a complete system architecture for a real-time chat application serving 1M users."
- "Analyze the implications of quantum computing on current cryptography standards."

Vision:
- Photo of a plant → "Identify this plant species."
- Photo of a document → "Extract all text from this document."
- Photo of a landmark → "What building is this? When was it built?"
```

---

## 7. Regression Test Suite

Run before every release:

```bash
# Unit tests
xcodebuild test -project ALIVE_APPLE.xcodeproj \
    -scheme "ALIVE APPLE" \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:ALIVE_APPLE_Tests/AutoRouterTests

xcodebuild test -project ALIVE_APPLE.xcodeproj \
    -scheme "ALIVE APPLE" \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:ALIVE_APPLE_Tests/ModelManagerTests

# Full test suite
xcodebuild test -project ALIVE_APPLE.xcodeproj \
    -scheme "ALIVE APPLE" \
    -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 8. Bug Report Template

```
## Bug: [Short title]

**Device:** iPhone 16, iOS 18.x
**Tier:** Fast / Moderate / Pro
**Model:** [model name]

**Steps to reproduce:**
1. ...
2. ...
3. ...

**Expected:** ...
**Actual:** ...

**Logs:** [attach console output]
**Memory at time:** X.X GB used / 8 GB
**Thermal state:** nominal / fair / serious / critical
```

---

*Testing is critical for on-device AI. Model behavior, memory, and thermal profiles can only be fully validated on physical iPhone 16 hardware.*
