import XCTest
@testable import MentalWellness

private final class MemoryChatStore: ChatStoring {
    var sessions: [ChatSession] = []
    func save(_ session: ChatSession) throws { sessions.append(session) }
    func deleteAll() throws { sessions = [] }
}

private actor StubGeminiService: GeminiServicing {
    var prompts: [String] = []
    var histories: [[ChatMessage]] = []
    var shouldFail = false
    var delay: UInt64 = 0
    func configure(fail: Bool = false, delay: UInt64 = 0) { shouldFail = fail; self.delay = delay }
    func generateReply(messages: [ChatMessage], systemPrompt: String) async throws -> String {
        histories.append(messages)
        prompts.append(systemPrompt)
        if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
        if shouldFail { throw GeminiError.httpStatus(503) }
        return "A supportive reply"
    }
}

@MainActor
final class ChatViewModelTests: XCTestCase {
    func testEveryTriggerClearsScreenBeforeLoadingSavingOrNetwork() async {
        for trigger in SafetyInterceptor.triggerWords {
            let service = StubGeminiService()
            let store = MemoryChatStore()
            var loads = 0
            let model = ChatViewModel(persona: .teacup, service: service, store: store, loadMindfulness: {
                loads += 1
                return "Local guide"
            })
            model.draft = "  \(trigger.uppercased())  "
            model.send()
            XCTAssertTrue(model.showCrisisIntervention)
            XCTAssertTrue(model.messages.isEmpty)
            XCTAssertNil(model.supportTopic)
            XCTAssertTrue(model.draft.isEmpty)
            XCTAssertFalse(model.isLoading)
            XCTAssertEqual(loads, 0)
            XCTAssertTrue(store.sessions.isEmpty)
            let calls = await service.histories.count
            XCTAssertEqual(calls, 0)
        }
    }

    func testTeacupLoadsOnceAndSendsRealHistoryWithoutName() async throws {
        let service = StubGeminiService()
        let store = MemoryChatStore()
        var loads = 0
        let model = ChatViewModel(persona: .teacup, service: service, store: store, loadMindfulness: {
            loads += 1; return "LOCAL_GUIDE_MARKER"
        })
        model.draft = "Help me ground"
        model.send()
        XCTAssertTrue(model.isLoading)
        try await waitUntilIdle(model)
        XCTAssertEqual(model.messages.map(\.role), [.user, .assistant])
        model.draft = "Let's continue"
        model.send()
        try await waitUntilIdle(model)
        let histories = await service.histories
        let prompts = await service.prompts
        XCTAssertEqual(histories.map(\.count), [1, 3])
        XCTAssertTrue(prompts.allSatisfy { $0.contains("LOCAL_GUIDE_MARKER") })
        XCTAssertEqual(loads, 1)
        XCTAssertEqual(store.sessions.last?.messages.count, 4)
    }

    func testOtherPersonasDoNotReadMindfulnessAndUseTheirPrompts() async throws {
        for persona in [Persona.basket, .boomerang, .lantern] {
            let service = StubGeminiService()
            let model = ChatViewModel(persona: persona, service: service, store: MemoryChatStore(), loadMindfulness: {
                XCTFail("Only Teacup may load RAG data"); return "unexpected"
            })
            model.draft = "Hello"
            model.send()
            try await waitUntilIdle(model)
            let prompt = await service.prompts.first
            XCTAssertEqual(prompt, try persona.systemPrompt())
        }
    }

    func testMissingBundleDataFailsBeforeSending() async {
        let service = StubGeminiService()
        let model = ChatViewModel(persona: .teacup, service: service, store: MemoryChatStore(), loadMindfulness: {
            throw MindfulnessDataError.unavailable
        })
        model.draft = "Hello"
        model.send()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.draft, "Hello")
        XCTAssertTrue(model.messages.isEmpty)
        let calls = await service.histories.count
        XCTAssertEqual(calls, 0)
    }

    func testRetryDoesNotDuplicateUserTurn() async throws {
        let service = StubGeminiService()
        await service.configure(fail: true)
        let model = ChatViewModel(persona: .basket, service: service, store: MemoryChatStore())
        model.draft = "A difficult day"
        model.send()
        try await waitUntilIdle(model)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.hasFailedMessage)
        XCTAssertEqual(model.messages.count, 1)
        await service.configure()
        model.retry()
        try await waitUntilIdle(model)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.hasFailedMessage)
        XCTAssertEqual(model.messages.map(\.role), [.user, .assistant])
    }

    func testResetCancelsAndDiscardsEvenAnUncooperativeLateReply() async throws {
        let service = StubGeminiService()
        await service.configure(delay: 150_000_000)
        let model = ChatViewModel(persona: .basket, service: service, store: MemoryChatStore())
        model.draft = "Hi"
        model.send()
        try await Task.sleep(nanoseconds: 20_000_000)
        model.resetSession()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(model.messages.isEmpty)
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(model.draft.isEmpty)
    }

    func testTeacupSuggestsHumanSupportEvenWhenServiceIsUnavailableAndResetsIt() async throws {
        let service = StubGeminiService()
        await service.configure(fail: true)
        let model = ChatViewModel(persona: .teacup, service: service, store: MemoryChatStore(), loadMindfulness: { "Guide" })
        model.draft = "People are bullying me in class"
        model.send()
        try await waitUntilIdle(model)
        XCTAssertEqual(model.supportTopic, .bullying)
        XCTAssertNotNil(model.errorMessage)
        model.resetSession()
        XCTAssertNil(model.supportTopic)
        model.draft = "I want to die because of bullying"
        model.send()
        XCTAssertTrue(model.showCrisisIntervention)
        XCTAssertNil(model.supportTopic)
        XCTAssertTrue(model.messages.isEmpty)
    }

    func testNonTeacupDoesNotAttachIssueCards() async throws {
        let model = ChatViewModel(persona: .basket, service: StubGeminiService(), store: MemoryChatStore())
        model.draft = "I'm lonely"
        model.send()
        try await waitUntilIdle(model)
        XCTAssertNil(model.supportTopic)
    }

    private func waitUntilIdle(_ model: ChatViewModel) async throws {
        for _ in 0..<200 {
            if !model.isLoading { return }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTFail("View model never left its loading state")
    }
}
