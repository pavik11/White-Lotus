import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSupportResources = false
    @State private var urgentSupportRequested = false
    @FocusState private var composerFocused: Bool
    private let bottomID = "conversationBottom"

    init(persona: Persona) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(persona: persona))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    companionIntroduction
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, persona: viewModel.persona)
                    }
                    if viewModel.isLoading {
                        HStack(spacing: 10) {
                            ProgressView().tint(viewModel.persona.tint)
                            Text("\(viewModel.persona.name) is thinking…").font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(WellnessTheme.card, in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("replyLoading")
                    }
                    if let warning = viewModel.storageWarning {
                        Label(warning, systemImage: "externaldrive.badge.exclamationmark")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let error = viewModel.errorMessage { errorCard(error) }
                    if let topic = viewModel.supportTopic {
                        SupportRecommendationCard(topic: topic) { showSupportResources = true }
                    }
                    Color.clear.frame(height: 1).id(bottomID)
                }
                .padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _ in scrollToBottom(proxy) }
            .onChange(of: viewModel.isLoading) { _ in scrollToBottom(proxy) }
            .onChange(of: viewModel.errorMessage) { _ in scrollToBottom(proxy) }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        }
        .background(viewModel.persona.surface.opacity(0.38))
        .navigationTitle(viewModel.persona.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.resetSession()
                    dismiss()
                } label: {
                    Label("Back to Home", systemImage: "chevron.left")
                        .font(.subheadline)
                }
                .accessibilityIdentifier("backToHome")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Help now") {
                    composerFocused = false
                    viewModel.presentCrisisIntervention()
                }.font(.subheadline.weight(.semibold))
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCrisisIntervention) {
            CrisisInterventionView { dismiss() }
        }
        .sheet(isPresented: $showSupportResources, onDismiss: {
            if urgentSupportRequested {
                urgentSupportRequested = false
                viewModel.presentCrisisIntervention()
            }
        }) {
            SupportResourcesView(initialTopic: viewModel.supportTopic ?? .connection) {
                viewModel.resetSession()
                urgentSupportRequested = true
            }
        }
        .onChange(of: viewModel.showCrisisIntervention) { shown in
            if shown { composerFocused = false }
        }
        .onDisappear { viewModel.resetSession() }
    }

    private var companionIntroduction: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(viewModel.persona.symbol).font(.system(size: 50)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.persona.title)
                    .font(.system(.title2, design: .serif, weight: .medium))
                    .foregroundStyle(viewModel.persona.tint)
                Text("AI companion · New conversation")
                    .font(.caption).foregroundStyle(.secondary)
            }
            // A UI greeting, not a fabricated model response in the network history.
            Text(viewModel.persona.greeting).font(.body)
            if viewModel.persona == .teacup {
                Button {
                    composerFocused = false
                    showSupportResources = true
                } label: {
                    Label("Find human support", systemImage: "person.2")
                        .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
                .accessibilityIdentifier("findHumanSupport")
            }
            if viewModel.messages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.persona.starters, id: \.self) { starter in
                        Button {
                            viewModel.draft = starter
                            viewModel.send()
                        } label: {
                            HStack {
                                Text(starter).multilineTextAlignment(.leading)
                                Spacer(minLength: 4)
                                Image(systemName: "arrow.up.left")
                            }
                            .font(.subheadline).padding(13)
                            .background(WellnessTheme.card, in: RoundedRectangle(cornerRadius: 13))
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .tint(viewModel.persona.tint)
            }
        }
        .padding(.bottom, 12)
    }

    private var composer: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField("What's on your mind?", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1...5).padding(13)
                    .background(WellnessTheme.background, in: RoundedRectangle(cornerRadius: 18))
                    .focused($composerFocused)
                    .disabled(viewModel.isLoading || viewModel.hasFailedMessage)
                    .accessibilityLabel("Message")
                    .accessibilityIdentifier("messageInput")
                Button {
                    composerFocused = false
                    viewModel.send()
                } label: {
                    Image(systemName: "arrow.up").font(.headline)
                        .foregroundStyle(.white).frame(width: 48, height: 48)
                        .background(viewModel.persona.tint.opacity(viewModel.canSend ? 1 : 0.35), in: Circle())
                }
                .disabled(!viewModel.canSend)
                .accessibilityLabel("Send message")
                .accessibilityIdentifier("sendMessage")
            }
            Text("AI can make mistakes. Your words are sent to Google for replies.")
                .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
        .background(WellnessTheme.card)
    }

    private func errorCard(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(error, systemImage: "exclamationmark.circle").font(.subheadline)
            if viewModel.hasFailedMessage {
                HStack(spacing: 24) {
                    Button("Try again") { viewModel.retry() }
                    Button("Edit message") { viewModel.editFailedMessage(); composerFocused = true }
                }.font(.subheadline.weight(.semibold))
            } else {
                Button("Dismiss") { viewModel.clearError() }.font(.subheadline.weight(.semibold))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(WellnessTheme.card, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("chatError")
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        proxy.scrollTo(bottomID, anchor: .bottom)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let persona: Persona

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 34) }
            VStack(alignment: .leading, spacing: 5) {
                Text(message.role == .user ? "You" : persona.name)
                    .font(.caption.weight(.semibold))
                // Plain Text avoids rendering remote tracking images or model-generated links.
                Text(message.content).font(.body).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .foregroundStyle(message.role == .user ? Color.white : Color.primary)
            .background(message.role == .user ? persona.tint : WellnessTheme.card,
                        in: RoundedRectangle(cornerRadius: 20))
            if message.role == .assistant { Spacer(minLength: 34) }
        }
        .accessibilityElement(children: .combine)
    }
}
