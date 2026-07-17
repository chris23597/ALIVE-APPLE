# ALIVE APPLE — Grok API Key Integration

**Version:** 1.0.0  
**Provider:** xAI (Grok)  
**Endpoint:** `https://api.x.ai/v1/chat/completions`  

---

## 1. Overview

ALIVE APPLE's **Pro tier** routes to Grok via xAI's API. The user brings their own API key. The app never transmits the key to any server except api.x.ai.

---

## 2. User Flow

### 2.1 First Pro Use

```
User taps "Pro" tier (or AutoRouter selects Pro)
  → Check if API key exists in Keychain
    → No key found:
       ┌──────────────────────────────────────┐
       │  "Pro tier uses Grok (cloud AI).     │
       │   You'll need an xAI API key.        │
       │                                      │
       │   Get one at: console.x.ai           │
       │                                      │
       │   [I have a key]  [Learn more]       │
       └──────────────────────────────────────┘
         ↓ [I have a key]
       ┌──────────────────────────────────────┐
       │  Paste your xAI API key:             │
       │  [________________________]          │
       │                                      │
       │  Your key is stored securely in      │
       │  the iOS Keychain and never shared.  │
       │                                      │
       │      [Cancel]      [Save & Use]      │
       └──────────────────────────────────────┘
         ↓
       → Validate key (quick test call)
         → Success: proceed with Pro inference
         → Failure: show error, let user retry

    → Key found:
       → Proceed with Pro inference (no prompt)
```

### 2.2 Settings — API Key Management

```
Settings → Pro Tier
┌──────────────────────────────────────┐
│  Grok API Key                        │
│  ─────────────────────────────────── │
│  Status: ✅ Connected                │
│  Key: xai-••••••••••abcd            │
│                                      │
│  [Change Key]    [Remove Key]        │
│                                      │
│  ─────────────────────────────────── │
│  Usage (this month)                  │
│  Tokens: ~45,000                     │
│  Est. cost: ~$0.23                   │
│                                      │
│  Get API key at: console.x.ai        │
└──────────────────────────────────────┘
```

---

## 3. Keychain Implementation

```swift
import Security
import Foundation

actor KeychainManager {
    
    private let service = "com.aliveapple.grok"
    private let account = "xai_api_key"
    
    /// Check if an API key is stored
    func hasKey() -> Bool {
        return (try? readKey()) != nil
    }
    
    /// Store API key in Keychain
    func saveKey(_ key: String) throws {
        // Delete existing key first
        try? deleteKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    /// Read API key from Keychain
    func readKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, 
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.readFailed(status: status)
        }
        
        return key
    }
    
    /// Delete API key from Keychain
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
    
    /// Validate key with a lightweight API call
    func validateKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/models")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case readFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Failed to save API key securely"
        case .readFailed: return "Failed to read API key"
        case .deleteFailed: return "Failed to remove API key"
        }
    }
}
```

---

## 4. Grok API Service

```swift
import Foundation

actor GrokAPIService {
    
    private let keychain = KeychainManager()
    
    struct GrokMessage: Codable {
        let role: String
        let content: GrokContent
    }
    
    enum GrokContent {
        case text(String)
        case multimodal(text: String, imageBase64: String)
    }
    
    struct GrokRequest: Codable {
        let model: String
        let messages: [APIMessage]
        let stream: Bool
        let temperature: Float?
        let max_tokens: Int?
    }
    
    struct APIMessage: Codable {
        let role: String
        let content: [ContentPart]
    }
    
    struct ContentPart: Codable {
        let type: String
        let text: String?
        let image_url: ImageURL?
    }
    
    struct ImageURL: Codable {
        let url: String  // "data:image/jpeg;base64,..."
    }
    
    func send(
        messages: [ChatMessage],
        stream: Bool = true,
        temperature: Float = 0.7
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = try keychain.readKey()
                    
                    var request = URLRequest(url: URL(string: "https://api.x.ai/v1/chat/completions")!)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = 30
                    
                    let body = GrokRequest(
                        model: "grok-2",
                        messages: messages.map { $0.toAPI() },
                        stream: stream,
                        temperature: temperature,
                        max_tokens: 4096
                    )
                    request.httpBody = try JSONEncoder().encode(body)
                    
                    if stream {
                        try await streamResponse(request: request, continuation: continuation)
                    } else {
                        let (data, _) = try await URLSession.shared.data(for: request)
                        // Parse non-streaming response
                        // ...
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func streamResponse(
        request: URLRequest,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (bytes, _) = try await URLSession.shared.bytes(for: request)
        
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let json = String(line.dropFirst(6))
            
            if json == "[DONE]" {
                continuation.finish()
                return
            }
            
            if let data = json.data(using: .utf8),
               let chunk = try? JSONDecoder().decode(ChatCompletionChunk.self, from: data),
               let content = chunk.choices.first?.delta.content {
                continuation.yield(content)
            }
        }
        
        continuation.finish()
    }
}

struct ChatCompletionChunk: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let delta: Delta
    }
    struct Delta: Codable {
        let content: String?
    }
}
```

---

## 5. Security Checklist

- [x] API key stored in iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- [x] Key never written to UserDefaults, logs, or disk
- [x] Key never sent to any server except `api.x.ai`
- [x] HTTPS enforced (App Transport Security)
- [x] Key validation uses lightweight endpoint (no token consumption)
- [x] Key displayed masked (xai-••••••••••abcd) in UI
- [x] One-tap removal from Settings
- [x] No key in app binary or source (user-supplied only)

---

## 6. Offline Fallback

When Pro tier is requested but internet is unavailable:

```
┌──────────────────────────────────────┐
│  "Pro tier requires internet.        │
│   You're currently offline.          │
│                                      │
│   Use Moderate tier instead?         │
│                                      │
│   [Use Moderate]    [Cancel]         │
└──────────────────────────────────────┘
```

Auto-fallback after 3 seconds if no user response.

---

*The user is in full control of their API key.  
ALIVE APPLE never stores, logs, or transmits the key except directly to xAI's API.*
