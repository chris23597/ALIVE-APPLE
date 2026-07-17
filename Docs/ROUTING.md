# ALIVE APPLE — Auto-Routing Logic

**Version:** 1.0.0  

---

## 1. Overview

The AutoRouter intelligently selects which tier (Fast / Moderate / Pro) to use for each inference request. It balances speed, quality, battery, thermal state, and connectivity — all on-device.

---

## 2. Routing Tiers

```
Fast ─────► Phi-4 Mini 3.8B (text) + SmolVLM2 2.2B (vision)
               Always available, always loaded
               Good for: simple Q&A, quick chat, basic vision

Moderate ─► Qwen2.5 7B (text) + Qwen2.5-VL 7B (vision)
               Loaded on-demand, unloaded after 5min idle
               Good for: complex reasoning, detailed vision

Pro ──────► Grok API (cloud)
               Requires: internet + user API key
               Good for: hardest problems, when on-device isn't enough
```

---

## 3. Routing Decision Algorithm

### 3.1 Input Signals

```swift
struct RoutingInputs {
    // Task signals
    let prompt: String
    let hasImage: Bool
    let conversationLength: Int
    
    // System state
    let memoryPressure: MemoryPressure    // .low | .normal | .warning | .critical
    let thermalState: ThermalState        // .nominal | .fair | .serious | .critical
    let batteryLevel: Float               // 0.0 ... 1.0
    let isOnline: Bool
    let hasAPIKey: Bool
    
    // User preference
    let forcedTier: RoutingTier?          // User override
}
```

### 3.2 Complexity Scoring

```swift
func complexityScore(prompt: String, conversationLength: Int) -> Float {
    var score: Float = 0.0
    
    // Length-based
    if prompt.count > 500 { score += 0.3 }
    if prompt.count > 1000 { score += 0.2 }
    if conversationLength > 10 { score += 0.2 }
    
    // Keyword signals (higher complexity)
    let complexKeywords = [
        "explain", "analyze", "compare", "contrast", "evaluate",
        "reason", "proof", "calculate", "solve", "debug",
        "code", "implement", "architecture", "design", "optimize",
        "why does", "how does", "what is the relationship",
        "step by step", "in detail", "comprehensive"
    ]
    
    let matches = complexKeywords.filter { prompt.lowercased().contains($0) }
    score += Float(matches.count) * 0.05
    
    // Code/math detection
    if prompt.contains("```") || prompt.contains("func ") || 
       prompt.contains("def ") || prompt.contains("class ") {
        score += 0.2
    }
    
    // Multi-part question detection
    let questionMarks = prompt.filter { $0 == "?" }.count
    if questionMarks > 1 { score += 0.15 }
    if questionMarks > 3 { score += 0.1 }
    
    // Plant ID / vision keywords
    let visionKeywords = [
        "identify this", "what plant", "what species", "what flower",
        "what kind of", "read this", "OCR", "scan this"
    ]
    if visionKeywords.contains(where: { prompt.lowercased().contains($0) }) {
        score += 0.4 // Often benefits from moderate VLM
    }
    
    return min(score, 1.0)
}
```

### 3.3 Decision Matrix

```swift
func decideTier(inputs: RoutingInputs) -> RoutingTier {
    // 1. User override always wins
    if let forced = inputs.forcedTier {
        return forced
    }
    
    // 2. Hard constraints
    if inputs.thermalState == .critical || inputs.memoryPressure == .critical {
        return .fast  // Safety: force Fast tier
    }
    if inputs.batteryLevel < 0.10 {
        return .fast  // Low battery: conserve power
    }
    
    let complexity = complexityScore(
        prompt: inputs.prompt,
        conversationLength: inputs.conversationLength
    )
    
    // 3. Check Pro availability
    if inputs.isOnline && inputs.hasAPIKey {
        if complexity > 0.85 || inputs.conversationLength > 30 {
            return .pro  // Very complex or very long → cloud
        }
        if inputs.hasImage && complexity > 0.6 {
            return .pro  // Complex vision → cloud Grok has great vision
        }
    }
    
    // 4. On-device routing
    if complexity > 0.5 || inputs.hasImage {
        // Moderate tier for complex tasks
        if inputs.thermalState == .serious || inputs.memoryPressure == .warning {
            return .fast  // System under pressure: downgrade
        }
        if inputs.batteryLevel < 0.25 {
            return .fast  // Battery moderate: downgrade to fast
        }
        return .moderate
    }
    
    // 5. Default: Fast tier
    return .fast
}
```

---

## 4. Thermal-Aware Downgrade

```swift
enum ThermalState {
    case nominal     // Normal operation
    case fair        // Slightly warm — OK for moderate
    case serious     // Hot — force Fast tier
    case critical    // Very hot — pause inference, notify user
}

// Monitor via:
// ProcessInfo.processInfo.thermalState
// Notification: ProcessInfo.thermalStateDidChangeNotification
```

**Behavior by thermal state:**

| Thermal State | Fast Tier | Moderate Tier | Pro Tier |
|--------------|-----------|---------------|----------|
| `.nominal` | ✅ Always | ✅ If needed | ✅ If online |
| `.fair` | ✅ Always | ✅ If needed (warn user) | ✅ If online |
| `.serious` | ✅ Always | ❌ Downgrade to Fast | ✅ If online |
| `.critical` | ⚠️ Pause after current | ❌ Disabled | ✅ If online |

---

## 5. Memory-Pressure Routing

```swift
enum MemoryPressure {
    case low        // >6GB free
    case normal     // 3-6GB free
    case warning    // 1-3GB free — unload Moderate, keep Fast
    case critical   // <1GB free — unload everything, notify
}
```

Monitor via `os_proc_available_memory()` or task_vm_info.

**When memory pressure hits `.warning`:**
1. Immediately unload Moderate tier models
2. Route all new requests to Fast
3. Show toast: "Switched to Fast mode — memory low"
4. Auto-reload Moderate when pressure returns to `.normal` for 30+ seconds

---

## 6. User Confirmation Gates

When AutoRouter wants to escalate from Fast → Moderate:

```
┌─────────────────────────────────┐
│  "This question may benefit     │
│   from a stronger model.        │
│                                 │
│   Switch to Moderate?           │
│   (Qwen2.5 7B · ~5s load time) │
│                                 │
│   [Always use Moderate] [Fast]  │
└─────────────────────────────────┘
```

- Single tap on tier badge toggles auto/manual
- Long press shows all tiers for manual selection
- "Always" preference stored in UserDefaults

When Pro is available:

```
┌─────────────────────────────────┐
│  "This looks complex.           │
│   Use Grok (cloud) for best     │
│   results?                      │
│                                 │
│   [Use Grok] [Use Moderate]     │
└─────────────────────────────────┘
```

---

## 7. Routing History & Learning

Track routing decisions to improve future selections:

```swift
struct RoutingRecord: Codable {
    let timestamp: Date
    let promptHash: String
    let decidedTier: RoutingTier
    let complexityScore: Float
    let userOverrode: Bool
    let userChoseTier: RoutingTier?
    let responseTimeMs: Int
    let userRatedHelpful: Bool?
}
```

**Future v2.0:** Train a tiny on-device classifier (CoreML) to predict tier preference based on user's override history.

---

## 8. Edge Cases

| Scenario | Behavior |
|----------|----------|
| No models loaded | Show "No models — import from USB or download" |
| Only Fast available | Route everything to Fast, show "Moderate unavailable" |
| Offline + Pro requested | Auto-fallback to Moderate (or Fast if Moderate unavailable) |
| Conversation crosses tiers | Don't switch mid-conversation unless critical (thermal/memory) |
| Vision without VLM loaded | Load Fast VLM automatically (3s load time) |
| Battery charging | Relax battery constraint (allow Moderate even at low %) |

---

## 9. Code Skeleton (Swift)

```swift
import Foundation
import os

actor AutoRouter {
    
    private let complexityThreshold: Float = 0.5
    private var routingHistory: [RoutingRecord] = []
    
    /// Main routing entry point
    func route(
        prompt: String,
        hasImage: Bool,
        conversationLength: Int,
        forcedTier: RoutingTier?
    ) async -> RoutingDecision {
        
        let inputs = await gatherSystemInputs(
            prompt: prompt,
            hasImage: hasImage,
            conversationLength: conversationLength,
            forcedTier: forcedTier
        )
        
        let tier = decideTier(inputs: inputs)
        let confidence = calculateConfidence(inputs: inputs, chosen: tier)
        
        let decision = RoutingDecision(
            tier: tier,
            confidence: confidence,
            reason: explainDecision(inputs: inputs, tier: tier)
        )
        
        await recordDecision(decision, inputs: inputs)
        return decision
    }
    
    // ... (implementations from above)
}
```

---

*The router runs entirely on-device — no network calls for routing decisions.  
All routing state is ephemeral, cleared on app background.*
