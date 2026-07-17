import Foundation
import SwiftData

/// A single chat message in a conversation
@Model
final class ChatMessage: Identifiable, Codable, @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var tierUsed: String?  // "fast", "moderate", "pro"
    var hasImage: Bool
    var imageData: Data?   // Optional attached image
    
    enum MessageRole: String, Codable, CaseIterable {
        case user
        case assistant
        case system
    }
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        tierUsed: String? = nil,
        hasImage: Bool = false,
        imageData: Data? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.tierUsed = tierUsed
        self.hasImage = hasImage
        self.imageData = imageData
    }
    
    // MARK: - Codable (manual conformance — SwiftData @Model cannot auto-synthesize)
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, tierUsed, hasImage, imageData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.role = try container.decode(MessageRole.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.tierUsed = try container.decodeIfPresent(String.self, forKey: .tierUsed)
        self.hasImage = try container.decodeIfPresent(Bool.self, forKey: .hasImage) ?? false
        self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(tierUsed, forKey: .tierUsed)
        try container.encode(hasImage, forKey: .hasImage)
        try container.encodeIfPresent(imageData, forKey: .imageData)
    }
    
    /// Convert to API-compatible format for Grok
    func toAPIMessage() -> [String: Any] {
        var dict: [String: Any] = [
            "role": role.rawValue,
            "content": content
        ]
        if let imageData, hasImage {
            dict["content"] = [
                ["type": "text", "text": content],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageData.base64EncodedString())"]]
            ]
        }
        return dict
    }
}

/// A conversation thread
@Model
final class Conversation: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage]
    
    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }
    
    // MARK: - Codable (manual conformance — SwiftData @Model cannot auto-synthesize)
    
    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt, messages
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.messages = try container.decode([ChatMessage].self, forKey: .messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(messages, forKey: .messages)
    }
}
