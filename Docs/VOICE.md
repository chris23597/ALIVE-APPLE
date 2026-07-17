# ALIVE APPLE — Voice Integration

**Version:** 1.0.0  

---

## 1. Overview

ALIVE APPLE supports full voice interaction:
- **Speech-to-Text (STT):** Convert spoken words to text for prompts
- **Text-to-Speech (TTS):** Read model responses aloud
- **Voice Chat Mode:** Continuous conversation with voice activity detection

All voice processing is on-device. No cloud speech services.

---

## 2. Speech-to-Text (STT)

### 2.1 Primary: Apple Speech Framework (Recommended)

Apple's built-in Speech framework provides on-device recognition for many languages. Zero model download, zero RAM overhead beyond what iOS already uses.

```swift
import Speech

actor VoiceService {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    /// Request speech recognition authorization
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    /// Start listening and return transcribed text stream
    func startListening() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                continuation.finish(throwing: VoiceError.recognitionRequestFailed)
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try? audioEngine.start()
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                if let result = result {
                    continuation.yield(result.bestTranscription.formattedString)
                    if result.isFinal {
                        continuation.finish()
                    }
                }
            }
            
            continuation.onTermination = { [weak self] _ in
                self?.stopListening()
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
```

### 2.2 Fallback: Whisper Small (CoreML)

For offline use when Apple Speech isn't available, or for higher accuracy:

| Property | Value |
|----------|-------|
| Model | openai/whisper-small (CoreML) |
| Size | ~180 MB |
| RAM | ~500 MB transient |
| Languages | 99 languages (English best) |
| Latency | ~1-2s for short utterances |

```swift
// Whisper integration via whisper.cpp Swift bindings or CoreML
func transcribeWithWhisper(audioURL: URL) async throws -> String {
    // 1. Load CoreML model
    // 2. Convert audio to 16kHz mono PCM
    // 3. Run inference
    // 4. Return transcribed text
}
```

---

## 3. Text-to-Speech (TTS)

### 3.1 Primary: AVSpeechSynthesizer (Built-in)

```swift
import AVFoundation

actor VoiceService {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, rate: Float = 0.52) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate  // 0.0–1.0, 0.5 is default
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Use a high-quality voice
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact") {
            utterance.voice = voice
        }
        
        // Stop any current speech before starting new
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
}
```

### 3.2 Streaming TTS

For long model responses, speak incrementally as tokens arrive:

```swift
func speakStream(stream: AsyncStream<String>) async {
    var buffer = ""
    var lastSpeakTime = Date()
    
    for await token in stream {
        buffer += token
        
        // Speak accumulated text every 500ms or at sentence boundaries
        let timeSinceLast = Date().timeIntervalSince(lastSpeakTime)
        let isSentenceEnd = [".", "!", "?", "\n"].contains(token.trimmingCharacters(in: .whitespaces).last)
        
        if timeSinceLast > 0.5 || isSentenceEnd {
            speak(buffer)
            buffer = ""
            lastSpeakTime = Date()
        }
    }
    
    // Speak remaining buffer
    if !buffer.isEmpty {
        speak(buffer)
    }
}
```

---

## 4. Voice Chat Mode

### 4.1 Flow

```
User taps 🎤
  → VoiceService.startListening()
    → VAD detects speech start
      → Show "Listening..." with waveform animation
    → User stops speaking (VAD detects silence for 1.5s)
      → Transcribe audio → show text
      → Send to InferenceEngine (as normal chat)
      → Stream response + speak via TTS
    → Auto-resume listening for next turn
  → User taps 🎤 again to end voice chat
```

### 4.2 Voice Activity Detection (VAD)

```swift
/// Simple energy-based VAD
func detectSpeechActivity(audioBuffer: [Float]) -> Bool {
    let rms = sqrt(audioBuffer.reduce(0) { $0 + $1 * $1 } / Float(audioBuffer.count))
    return rms > 0.02  // Threshold tuned for iPhone mic
}
```

**Silence timeout:** 1.5 seconds of audio below threshold → end of utterance.

---

## 5. Audio Session Management

```swift
func configureAudioSession(for mode: AudioMode) throws {
    let session = AVAudioSession.sharedInstance()
    
    switch mode {
    case .recording:
        try session.setCategory(.record, mode: .measurement)
    case .playback:
        try session.setCategory(.playback, mode: .default)
    case .voiceChat:
        try session.setCategory(.playAndRecord, 
                                 mode: .voiceChat,
                                 options: [.allowBluetooth, .defaultToSpeaker])
    }
    
    try session.setActive(true)
}
```

---

## 6. Permissions

Required Info.plist keys:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>ALIVE APPLE uses speech recognition to transcribe your voice prompts. All processing is on-device.</string>

<key>NSMicrophoneUsageDescription</key>
<string>ALIVE APPLE needs microphone access for voice input and chat mode.</string>
```

---

## 7. Error Handling

| Error | Handling |
|-------|----------|
| Permission denied | Show Settings link, fallback to keyboard input |
| No speech detected | "Didn't catch that — tap mic and try again" |
| Recognition timeout | Auto-stop after 30s of silence, show partial result |
| TTS voice unavailable | Fallback to default system voice |
| Audio route change | Handle Bluetooth connect/disconnect, pause TTS |

---

## 8. UI Integration

```
ChatView
├── 🎤 button (bottom toolbar)
│   ├── Tap → start voice input
│   ├── Hold → voice chat mode (continuous)
│   └── While recording: pulsing red ring
├── 🔊 button (near each response)
│   └── Tap → speak this message
└── Voice chat banner (when active)
    └── "Voice Chat active · say 'stop' or tap to end"
```

---

*Voice processing is fully on-device. No audio leaves the device.  
Apple Speech framework requires no model download and works offline for supported languages.*
