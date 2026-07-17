import SwiftUI

/// Main chat interface with streaming, empty state, and design tokens
struct ChatView: View {
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services
    @State private var chatVM = ChatViewModel()
    @State private var messageText: String = ""
    @State private var isRecording: Bool = false
    @FocusState private var isInputFocused: Bool
    
    private var tierColor: Color { chatVM.currentTier.color }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if chatVM.messages.isEmpty && !chatVM.isGenerating {
                emptyState
            } else {
                messageList
            }
            
            inputBar
        }
        .background(AliveTokens.bgDeepest.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(RoutingTier.allCases, id: \.self) { tier in
                        Button {
                            chatVM.switchTier(tier)
                        } label: {
                            HStack {
                                Text(tier.label)
                                if chatVM.currentTier == tier {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        chatVM.enableAutoRouting()
                    } label: {
                        HStack {
                            Text("Auto-Route")
                            if appState.routingMode == .auto {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    TierBadge(tier: chatVM.currentTier)
                }
            }
        }
        .toolbarBackground(AliveTokens.bgDeepest, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            chatVM.services = services
            chatVM.appState = appState
        }
    }
    
    // MARK: - Empty state (first impression)
    
    private var emptyState: some View {
        VStack(spacing: AliveTokens.lg) {
            Spacer(minLength: AliveTokens.xxl)
            
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(tierColor)
            }
            
            Text("On-device. Private. Offline.")
                .font(.headline)
                .foregroundColor(AliveTokens.textPrimary)
            
            Text("ALIVE stays on your iPhone. No cloud required for Fast & Moderate.")
                .font(.subheadline)
                .foregroundColor(AliveTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AliveTokens.xxl)
            
            // Status strip
            HStack(spacing: AliveTokens.md) {
                statusChip(icon: chatVM.currentTier.systemImage, text: chatVM.currentTier.label, color: tierColor)
                statusChip(
                    icon: "internaldrive",
                    text: memoryLabel,
                    color: AliveTokens.textSecondary
                )
                statusChip(
                    icon: appState.isOnline ? "wifi" : "wifi.slash",
                    text: appState.isOnline ? "Online" : "Offline",
                    color: appState.isOnline ? AliveTokens.accentPro : AliveTokens.textSecondary
                )
            }
            .padding(.top, AliveTokens.sm)
            
            // Starter chips
            VStack(spacing: AliveTokens.sm) {
                starterChip("Who are you?")
                starterChip("What can you do offline?")
                starterChip("Help me care for a houseplant")
                starterChip("How does privacy work here?")
            }
            .padding(.top, AliveTokens.md)
            .padding(.horizontal, AliveTokens.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var memoryLabel: String {
        switch appState.memoryPressure {
        case .low, .normal: return "RAM OK"
        case .warning: return "RAM tight"
        case .critical: return "RAM low"
        }
    }
    
    private func statusChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AliveTokens.bgCard)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AliveTokens.border, lineWidth: 1))
    }
    
    private func starterChip(_ title: String) -> some View {
        Button {
            messageText = title
            sendMessage()
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AliveTokens.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(AliveTokens.textTertiary)
            }
            .padding(.horizontal, AliveTokens.lg)
            .padding(.vertical, AliveTokens.md)
            .background(AliveTokens.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AliveTokens.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Messages
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AliveTokens.lg) {
                    ForEach(chatVM.messages) { message in
                        MessageBubble(
                            message: message,
                            tierColor: tierColorForMessage(message)
                        )
                        .id(message.id)
                    }
                    
                    if chatVM.isGenerating && !chatVM.currentStreamingMessage.isEmpty {
                        MessageBubble(
                            message: ChatMessage(
                                role: .assistant,
                                content: chatVM.currentStreamingMessage,
                                tierUsed: chatVM.currentTier.rawValue
                            ),
                            isStreaming: true,
                            tierColor: tierColor
                        )
                        .id("streaming")
                    }
                    
                    if let error = chatVM.errorMessage {
                        ErrorBanner(message: error)
                    }
                }
                .padding(.horizontal, AliveTokens.lg)
                .padding(.vertical, AliveTokens.md)
            }
            .onChange(of: chatVM.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: chatVM.currentStreamingMessage) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private func tierColorForMessage(_ message: ChatMessage) -> Color {
        guard let raw = message.tierUsed,
              let tier = RoutingTier(rawValue: raw) else {
            return AliveTokens.accentFast
        }
        return tier.color
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("ALIVE APPLE")
                .font(.headline)
                .foregroundColor(AliveTokens.textPrimary)
            
            Spacer()
            
            Menu {
                ForEach(appState.availableTiers, id: \.self) { tier in
                    Button(action: { chatVM.switchTier(tier) }) {
                        HStack {
                            Image(systemName: tier.systemImage)
                                .foregroundColor(tier.color)
                            Text(tier.label)
                            if chatVM.currentTier == tier {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                TierBadge(tier: chatVM.currentTier)
            }
        }
        .padding(.horizontal, AliveTokens.lg)
        .padding(.vertical, AliveTokens.sm)
        .background(AliveTokens.bgDeepest.opacity(0.98))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AliveTokens.border)
                .frame(height: 1)
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: AliveTokens.md) {
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 20))
                    .foregroundColor(isRecording ? AliveTokens.accentError : AliveTokens.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isRecording ? AliveTokens.accentError.opacity(0.15) : Color.clear)
                    )
            }
            
            TextField("Ask anything...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundColor(AliveTokens.textPrimary)
                .padding(.horizontal, AliveTokens.md)
                .padding(.vertical, AliveTokens.sm)
                .background(AliveTokens.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AliveTokens.border, lineWidth: 1)
                )
                .focused($isInputFocused)
                .onSubmit { sendMessage() }
                .disabled(chatVM.isGenerating)
            
            Button(action: sendMessage) {
                Image(systemName: chatVM.isGenerating ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespaces).isEmpty && !chatVM.isGenerating
                        ? AliveTokens.textTertiary
                        : tierColor
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty && !chatVM.isGenerating)
        }
        .padding(.horizontal, AliveTokens.lg)
        .padding(.vertical, 10)
        .background(AliveTokens.bgCard)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = messageText
        messageText = ""
        Task {
            await chatVM.sendMessage(text)
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        // VoiceService wiring remains F9
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if chatVM.isGenerating {
            withAnimation {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        } else if let lastId = chatVM.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false
    var tierColor: Color = AliveTokens.accentFast
    
    var body: some View {
        HStack(alignment: .top, spacing: AliveTokens.md) {
            if message.role == .assistant {
                Circle()
                    .fill(tierColor.opacity(0.25))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(tierColor)
                    )
            } else {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(isStreaming ? message.content + " ▌" : message.content)
                    .font(.body)
                    .foregroundColor(AliveTokens.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                        ? AliveTokens.bgCard
                        : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                HStack(spacing: AliveTokens.sm) {
                    if let tier = message.tierUsed {
                        Text(tier)
                            .font(.caption2)
                            .foregroundColor(tierColor.opacity(0.9))
                    }
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(AliveTokens.textSecondary)
                }
                .padding(.horizontal, 4)
            }
            
            if message.role == .user {
                Circle()
                    .fill(AliveTokens.accentFast.opacity(0.25))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(AliveTokens.accentFast)
                    )
            } else {
                Spacer(minLength: 24)
            }
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AliveTokens.accentModerate)
            Text(message)
                .font(.caption)
                .foregroundColor(AliveTokens.textSecondary)
            Spacer()
        }
        .padding(AliveTokens.md)
        .background(AliveTokens.accentModerate.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatView()
            .environment(AppState())
            .preferredColorScheme(.dark)
    }
}
