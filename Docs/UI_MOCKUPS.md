# ALIVE APPLE — UI Mockups & Design System

**Version:** 1.0.0  
**Design Language:** Native iOS + Fluent-inspired  

---

## 1. Design Tokens

### 1.1 Colors (Dark Mode — Primary)

```
Background (deepest):    #0D0D0D  — app background, tab bar
Background (card):       #1A1A1A  — chat bubbles (user), cards
Background (elevated):   #242424  — input bar, sheets, modals
Background (hover):      #2E2E2E  — selected items, active states

Text (primary):          #FFFFFF  — body text, headers
Text (secondary):        #999999  — timestamps, metadata
Text (tertiary):         #666666  — placeholder text

Accent (Fast tier):      #4CAF50  — green: fast, available
Accent (Moderate tier):  #FF9800  — orange: moderate, loading
Accent (Pro tier):       #2196F3  — blue: pro, cloud
Accent (None/Error):     #F44336  — red: error, offline, none loaded

Code background:         #1E1E1E  — code blocks
Code text:               #D4D4D4  — code text
Border:                  #333333  — dividers, outlines

Bubble (user):           #1A1A1A  — user message
Bubble (assistant):      transparent — assistant message (no bubble)
```

### 1.2 Typography

```
// System fonts only — no custom fonts needed
Large Title:  .system(size: 34, weight: .bold)
Title 1:      .system(size: 28, weight: .bold)
Title 2:      .system(size: 22, weight: .semibold)
Headline:     .system(size: 17, weight: .semibold)
Body:         .system(size: 17, weight: .regular)
Callout:      .system(size: 16, weight: .regular)
Subhead:      .system(size: 15, weight: .regular)
Footnote:     .system(size: 13, weight: .regular)
Caption:      .system(size: 12, weight: .regular)

Code:         .system(size: 14, weight: .regular, design: .monospaced)
```

### 1.3 Spacing

```
xs: 4pt
sm: 8pt
md: 12pt
lg: 16pt
xl: 20pt
xxl: 24pt
section: 32pt
```

---

## 2. Screen Mockups

### 2.1 Dashboard (Main Screen)

```
┌──────────────────────────────────────────┐
│  ALIVE APPLE                     ⚙️      │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  🟢 Fast Tier                    │   │
│  │  Phi-4 Mini 3.8B · 2.4GB        │   │
│  │  Ready                           │   │
│  │                          [▼]     │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  📊 System                       │   │
│  │  RAM: 3.2GB free  │  🌡 Nominal  │   │
│  │  🔋 78%           │  📶 Offline  │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  Quick Actions                   │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐     │   │
│  │  │ 📷   │ │ 🎤   │ │ 📄   │     │   │
│  │  │Vision│ │Voice │ │Files │     │   │
│  │  └──────┘ └──────┘ └──────┘     │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  "Ask anything..."               │   │
│  │                          [➤]     │   │
│  └──────────────────────────────────┘   │
│                                          │
│  [📝 Chat]  [📷 Vision]  [📥 Models] [⚙️]│
└──────────────────────────────────────────┘
```

### 2.2 Chat View

```
┌──────────────────────────────────────────┐
│  ← Chat                    Fast 🟢  ...  │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ User:                            │   │
│  │ "What's the best way to water    │   │
│  │  a Monstera deliciosa?"          │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Monstera deliciosa (Swiss cheese       │
│  plant) thrives with these watering     │
│  guidelines:                            │
│                                          │
│  **1. Frequency**                       │
│  - Water every 1-2 weeks                │
│  - Allow top 2 inches of soil to dry    │
│    between waterings                    │
│                                          │
│  **2. Signs of overwatering:**          │
│  - Yellow leaves                        │
│  - Soft, brown spots                    │
│                                          │
│  ```                                     │
│  Check soil moisture:                   │
│  - Finger test: 2" deep                 │
│  - Moisture meter: 3-4 reading          │
│  ```                                     │
│                                    🔊    │
│  ───────────────────────────────────    │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ [+]  "Ask a follow-up..."   🎤 ➤ │   │
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

### 2.3 Tier Picker (Expanded)

```
┌──────────────────────────────────────────┐
│  Select Model Tier                  ✕    │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 🟢 Fast                          │   │
│  │ Phi-4 Mini 3.8B                  │   │
│  │ 2.4 GB · On Device · Always Ready│   │
│  │                            ✓     │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 🟠 Moderate                      │   │
│  │ Qwen2.5 7B                       │   │
│  │ 4.4 GB · On Device · Loads in 3s │   │
│  │                                  │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 🔵 Pro                           │   │
│  │ Grok API (xAI)                   │   │
│  │ Cloud · Requires internet + key  │   │
│  │                                  │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ ⚪ None                          │   │
│  │ No model loaded                  │   │
│  │                                  │   │
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

### 2.4 Vision View

```
┌──────────────────────────────────────────┐
│  ← Vision              Fast VLM 🟢       │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │                                  │   │
│  │        [Camera Viewfinder]       │   │
│  │                                  │   │
│  │         Tap to capture           │   │
│  │                                  │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────┐                       │
│  │ Recent photo │  "What plant is this?"│
│  │   [thumb]    │                       │
│  └──────────────┘  [📷 Capture] [🖼 Gallery]│
│                                          │
│  ─────────────────────────────────────── │
│                                          │
│  **Analysis**                            │
│  This appears to be *Monstera            │
│  deliciosa*, commonly known as the       │
│  Swiss cheese plant.                     │
│                                          │
│  Key identifiers:                        │
│  - Large, heart-shaped leaves            │
│  - Distinctive holes (fenestrations)     │
│  - Deep green coloration                 │
│                                    🔊    │
└──────────────────────────────────────────┘
```

### 2.5 Model Import View

```
┌──────────────────────────────────────────┐
│  ← Import Models                    ✕    │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ 💾 USB Drive Detected            │   │
│  │ "ALIVE_MODELS" · 256GB · exFAT   │   │
│  │ 4 model files found              │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Available Models:                       │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ ✅ Phi-4-mini-Q4_K_M.gguf        │   │
│  │    2.4 GB · Text LLM · Fast Tier │   │
│  │                          [Import]│   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ ⬜ qwen2.5-7b-Q4_K_M.gguf        │   │
│  │    4.4 GB · Text LLM · Moderate  │   │
│  │                          [Import]│   │
│  └──────────────────────────────────┘   │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │ ⬜ SmolVLM2-2.2B-Q4_K_M.gguf     │   │
│  │    1.4 GB · VLM · Fast Tier      │   │
│  │                          [Import]│   │
│  └──────────────────────────────────┘   │
│                                          │
│  Space available: 98GB                   │
│                                          │
│  [Import All (4 files, 12.9 GB)]        │
└──────────────────────────────────────────┘
```

### 2.6 Settings View

```
┌──────────────────────────────────────────┐
│  ← Settings                              │
│                                          │
│  General                                 │
│  ┌──────────────────────────────────┐   │
│  │ Appearance          Dark →       │   │
│  │ Haptic Feedback     ✓            │   │
│  │ Auto-play voice     ✗            │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Pro Tier                                │
│  ┌──────────────────────────────────┐   │
│  │ Grok API Key       ✅ Connected  │   │
│  │ Default Pro temp   0.7           │   │
│  │ Max tokens          4096         │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Models                                  │
│  ┌──────────────────────────────────┐   │
│  │ Manage Models       4 imported → │   │
│  │ Storage Used        8.7 GB       │   │
│  │ Import from USB                  │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Data                                    │
│  ┌──────────────────────────────────┐   │
│  │ Export Chats        JSON →       │   │
│  │ Clear All Chats                  │   │
│  │ Clear Model Cache                │   │
│  └──────────────────────────────────┘   │
│                                          │
│  About                                   │
│  ┌──────────────────────────────────┐   │
│  │ Version             1.0.0        │   │
│  │ Target             iPhone 16     │   │
│  │ Privacy Policy                  │   │
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

---

## 3. Component Library

### 3.1 Tier Badge

```swift
// Always visible in navigation bar
struct TierBadge: View {
    let tier: RoutingTier
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tier.color)
                .frame(width: 8, height: 8)
            Text(tier.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tier.color.opacity(0.15))
        .clipShape(Capsule())
    }
}
```

### 3.2 Streaming Text

```swift
// Animated cursor during streaming
struct StreamingText: View {
    let text: String
    let isStreaming: Bool
    
    var body: some View {
        Text(LocalizedStringKey(text))
            + Text(isStreaming ? " ▌" : "")
                .foregroundColor(.accentColor)
                .opacity(isStreaming ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isStreaming)
    }
}
```

### 3.3 Memory Gauge

```swift
struct MemoryGauge: View {
    let usedGB: Float
    let totalGB: Float = 8.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RAM")
                .font(.caption)
                .foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usageColor)
                        .frame(width: geo.size.width * CGFloat(usedGB / totalGB), height: 6)
                }
            }
            .frame(height: 6)
            HStack {
                Text(String(format: "%.1f GB free", totalGB - usedGB))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f / %.1f GB", usedGB, totalGB))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var usageColor: Color {
        let pct = usedGB / totalGB
        if pct > 0.85 { return .red }
        if pct > 0.7 { return .orange }
        return .green
    }
}
```

---

## 4. Animations

| Element | Animation |
|---------|-----------|
| Tier switch | Crossfade + scale (0.2s) |
| Message appear | Slide up + fade (0.3s spring) |
| Streaming cursor | Blink (0.5s infinite) |
| Button tap | Scale 0.97 + spring back |
| Sheet present | Slide up (0.3s easeOut) |
| Model loading | Skeleton shimmer |
| Error toast | Slide down + auto-dismiss |

---

## 5. Accessibility

- All buttons have accessibility labels
- Tier badge: "Current model: Fast tier, Phi-4 Mini"
- Chat messages: "Message from you: [text]" / "Response: [text]"
- Voice: "Double tap to start voice input"
- Dynamic Type support on all text
- Minimum contrast ratio: 4.5:1 (WCAG AA)

---

*Design follows Apple HIG with Fluent-inspired depth and motion.  
Dark mode is the primary theme; light mode mirrors the same token structure.*
