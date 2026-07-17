import Foundation
import AVFoundation
import Speech

/// On-device voice service: STT via Apple Speech, TTS via AVSpeechSynthesizer
actor VoiceService {
    
    // MARK: - STT
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - TTS
    
    private let synthesizer = AVSpeechSynthesizer()
    
    // MARK: - Authorization
    
    func requestSTTAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    // MARK: - Speech-to-Text
    
    /// Start listening and stream transcriptions
    /// Thread-safe: guards against double-finish on continuation from recognitionTask callback
    func startListening() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // Use a lock to prevent double-finish (e.g. error + final result arriving together)
            let finished = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            finished.initialize(to: false)
            let lock = NSLock()
            
            func safeFinish(throwing error: Error? = nil) {
                lock.lock()
                defer { lock.unlock() }
                guard !finished.pointee else { return }
                finished.pointee = true
                if let error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                lock.lock()
                finished.pointee = true
                lock.unlock()
                Task { await self.stopListening() }
            }
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = recognitionRequest else {
                    safeFinish(throwing: VoiceError.recognitionRequestFailed)
                    return
                }
                recognitionRequest.shouldReportPartialResults = true
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
                
                recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                    if let error = error {
                        safeFinish(throwing: VoiceError.recognitionFailed(error))
                        return
                    }
                    if let result = result {
                        let isFinal = result.isFinal
                        continuation.yield(result.bestTranscription.formattedString)
                        if isFinal {
                            safeFinish()
                        }
                    }
                }
            } catch {
                safeFinish(throwing: error)
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    // MARK: - Text-to-Speech
    
    func speak(_ text: String, rate: Float = 0.52) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact") {
            utterance.voice = voice
        }
        
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
    
    // MARK: - Voice Activity Detection
    
    /// Simple energy-based VAD
    func detectSpeechActivity(audioBuffer: [Float]) -> Bool {
        let rms = sqrt(audioBuffer.reduce(0) { $0 + $1 * $1 } / Float(audioBuffer.count))
        return rms > 0.02
    }
    
    // MARK: - Streaming TTS
    
    /// Speak tokens incrementally as they arrive from inference
    func speakStream(_ stream: AsyncStream<String>) async {
        var buffer = ""
        var lastSpeakTime = Date()
        
        for await token in stream {
            buffer += token
            
            let timeSinceLast = Date().timeIntervalSince(lastSpeakTime)
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            let isSentenceEnd = [".", "!", "?", "\n"].contains(trimmed.last)
            
            if timeSinceLast > 0.5 || isSentenceEnd {
                speak(buffer)
                buffer = ""
                lastSpeakTime = Date()
            }
        }
        
        if !buffer.isEmpty {
            speak(buffer)
        }
    }
}

// MARK: - Errors

enum VoiceError: LocalizedError {
    case recognitionRequestFailed
    case audioEngineFailed
    case notAuthorized
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .audioEngineFailed:
            return "Failed to start audio engine"
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .recognitionFailed(let error):
            return "Recognition failed: \(error.localizedDescription)"
        }
    }
}
