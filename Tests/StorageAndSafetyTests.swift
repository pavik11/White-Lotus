import XCTest
@testable import MentalWellness

final class StorageAndSafetyTests: XCTestCase {
    func testKeywordNormalizationAndOrdinaryMessage() throws {
        let scanner = SafetyInterceptor()
        XCTAssertNoThrow(try scanner.validate("I'm anxious about homework"))
        XCTAssertThrowsError(try scanner.validate("want\n to\t die"))
        XCTAssertThrowsError(try scanner.validate("kill-myself"))
        XCTAssertThrowsError(try scanner.validate("ＳＵＩＣＩＤＥ"))
        XCTAssertThrowsError(try scanner.validate("substance abuse"))
    }

    func testRealBundledGuideAndTeacupPrompt() throws {
        // Unit tests run hosted in the app so this checks its actual Copy Bundle Resources phase.
        let text = try MindfulnessDataLoader().load()
        XCTAssertTrue(text.contains("FIVE-SENSES GROUNDING"))
        XCTAssertTrue(text.contains("STOP"))
        XCTAssertTrue(text.contains("GENTLE PACED BREATHING"))
        XCTAssertTrue(try Persona.teacup.systemPrompt(mindfulnessData: text).contains(text))
        XCTAssertThrowsError(try Persona.teacup.systemPrompt(mindfulnessData: "  "))
    }

    func testArchiveRoundTripSnapshotUpdateBackupExclusionAndDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalChatStore(directory: directory)
        let id = UUID()
        let first = ChatMessage(role: .user, content: "A private test message")
        try store.save(.init(id: id, persona: .basket, messages: [first], updatedAt: Date()))
        let reply = ChatMessage(role: .assistant, content: "I hear you")
        try store.save(.init(id: id, persona: .basket, messages: [first, reply], updatedAt: Date()))
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let saved = try decoder.decode(ChatSession.self, from: Data(contentsOf: XCTUnwrap(files.first)))
        XCTAssertEqual(saved.id, id)
        XCTAssertEqual(saved.persona, .basket)
        XCTAssertEqual(saved.messages.map(\.content), [first.content, reply.content])
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        try store.deleteAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
}


final class SupportResourcesTests: XCTestCase {
    func testTopicsMatchWholePhrasesAndAvoidTreatingBoredomAsACrisis() {
        XCTAssertEqual(SupportTopic.suggested(for: "I’m being BULLIED"), .bullying)
        XCTAssertEqual(SupportTopic.suggested(for: "I have no one to talk to"), .connection)
        XCTAssertEqual(SupportTopic.suggested(for: "I feel lost about my future"), .feelingLost)
        XCTAssertEqual(SupportTopic.suggested(for: "I can’t afford food"), .basicNeeds)
        XCTAssertNil(SupportTopic.suggested(for: "I'm bored; tell me a joke"))
        XCTAssertNil(SupportTopic.suggested(for: "I lost my pencil"))
        XCTAssertNil(SupportTopic.suggested(for: "I'm studying cellular isolation"))
    }

    func testCuratedLinksAreFixedOfficialHTTPSResourcesWithoutChatQueries() {
        let allowedHosts = Set(["www.stopbullying.gov", "www.nami.org", "helplinefaqs.nami.org", "211.org"])
        for topic in SupportTopic.allCases {
            XCTAssertFalse(topic.resources.isEmpty)
            for resource in topic.resources {
                XCTAssertEqual(resource.website.scheme, "https")
                XCTAssertTrue(allowedHosts.contains(resource.website.host ?? ""))
                XCTAssertNil(resource.website.query)
            }
        }
    }
}
