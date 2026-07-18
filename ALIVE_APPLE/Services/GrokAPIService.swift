import Foundation

/// Grok (xAI) API service for Pro tier cloud inference.
/// Uses the user's own API key stored in the iOS Keychain.
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
                    let apiKey = try await keychain.readKey()
                    
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
