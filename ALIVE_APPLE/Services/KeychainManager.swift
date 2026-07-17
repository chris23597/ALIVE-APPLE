import Foundation
import Security

/// Secure storage for API keys using iOS Keychain
actor KeychainManager {
    
    private let service = "com.aliveapple.grok"
    private let account = "xai_api_key"
    
    // MARK: - CRUD Operations
    
    func hasKey() -> Bool {
        (try? readKey()) != nil
    }
    
    func saveKey(_ key: String) throws {
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
    
    // MARK: - Validation
    
    func validateKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/models")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
    
    // MARK: - Display
    
    func maskedKey() throws -> String {
        let key = try readKey()
        guard key.count > 8 else { return "••••" }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
}

// MARK: - Grok API Service

actor GrokAPIService {
    
    private let keychain = KeychainManager()
    
    private struct ChatRequest: Codable {
        let model: String
        let messages: [APIMessage]
        let stream: Bool
        let temperature: Float
        let max_tokens: Int
    }
    
    private struct APIMessage: Codable {
        let role: String
        let content: [ContentPart]
    }
    
    private struct ContentPart: Codable {
        let type: String
        let text: String?
        let image_url: ImageURL?
        
        enum CodingKeys: String, CodingKey {
            case type
            case text
            case image_url
        }
    }
    
    private struct ImageURL: Codable {
        let url: String
        
        enum CodingKeys: String, CodingKey {
            case url
        }
    }
    
    struct StreamChunk: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let delta: Delta
        }
        struct Delta: Codable {
            let content: String?
        }
    }
    
    func send(
        messages: [ChatMessage],
        stream: Bool = true,
        temperature: Float = 0.7,
        maxTokens: Int = 4096
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
                    
                    let apiMessages = messages.map { msg -> APIMessage in
                        let parts: [ContentPart]
                        if msg.hasImage, let imageData = msg.imageData {
                            parts = [
                                ContentPart(type: "text", text: msg.content, image_url: nil),
                                ContentPart(type: "image_url", text: nil, image_url: ImageURL(
                                    url: "data:image/jpeg;base64,\(imageData.base64EncodedString())"
                                ))
                            ]
                        } else {
                            parts = [ContentPart(type: "text", text: msg.content, image_url: nil)]
                        }
                        return APIMessage(role: msg.role.rawValue, content: parts)
                    }
                    
                    let body = ChatRequest(
                        model: "grok-2",
                        messages: apiMessages,
                        stream: stream,
                        temperature: temperature,
                        max_tokens: maxTokens
                    )
                    request.httpBody = try JSONEncoder().encode(body)
                    
                    if stream {
                        let (bytes, _) = try await URLSession.shared.bytes(for: request)
                        for try await line in bytes.lines {
                            guard line.hasPrefix("data: ") else { continue }
                            let json = String(line.dropFirst(6))
                            if json == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            if let data = json.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                               let content = chunk.choices.first?.delta.content {
                                continuation.yield(content)
                            }
                        }
                        continuation.finish()
                    } else {
                        let (data, _) = try await URLSession.shared.data(for: request)
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case readFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save API key securely"
        case .readFailed:
            return "Failed to read API key"
        case .deleteFailed:
            return "Failed to remove API key"
        }
    }
}
