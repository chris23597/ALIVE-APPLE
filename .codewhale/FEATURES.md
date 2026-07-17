# FEATURES — ALIVE APPLE (agent-os)

**Goal:** Ship a pure on-device, offline-first AI agent for iPhone 16 that loads Fast tier, chats with streaming, and looks like the product in UI_MOCKUPS.

| Status | Feature | Proof command |
|--------|---------|---------------|
| [x] | F0: Project scaffold (PRD, architecture, Swift MVVM shell, USB scripts) | Docs + source tree present |
| [x] | F1: Agent-os harness (FEATURES + HANDOFF filled for CodeWhale) | This file + HANDOFF.md |
| [x] | F2: On-device system prompt + ChatML prompt build | Build ChatViewModel injects system message |
| [x] | F3: Empty-chat + design tokens aesthetics pass | ChatView empty state + DesignTokens |
| [ ] | F4: **Real** Fast-tier GGUF path (link llama.cpp / Metal on Mac+Xcode) | Device/sim: load Phi-4 Mini, stream non-sim tokens |
| [ ] | F5: USB import → model appears in list → Fast warm | Device with USB: import + Ready badge |
| [ ] | F6: Stop generation + clear empty/error states | Manual QA on device |
| [ ] | F7: Markdown bubbles (headers/lists/code) | Visual QA |
| [ ] | F8: Thermal/RAM block UI before Moderate load | Manual QA under thermal pressure |
| [ ] | F9: Voice mic wired to VoiceService | Device mic test |
| [ ] | F10: Dashboard or intentional chat-first PRD update | Product decision |

## Rules

- One unchecked row per CodeWhale session when possible  
- Check a box only after the proof runs (or honest BLOCKED note in HANDOFF)  
- Windows ALIVE (`C:\ALIVE`) is **reference only** — no PyQt6/Ollama ports into iOS  
