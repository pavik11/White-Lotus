import XCTest
@testable import MentalWellness

final class StubURLProtocol: URLProtocol {
    static var responseHeaders: [String: String] = [:]
    static var handler: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler, let url = request.url else { throw URLError(.badURL) }
            let (code, data) = try handler(request)
            let response = HTTPURLResponse(url: url, statusCode: code, httpVersion: nil,
                                           headerFields: ["Content-Type": "application/json"].merging(Self.responseHeaders) { _, new in new })!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

final class GeminiServiceTests: XCTestCase {
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        StubURLProtocol.handler = nil
        StubURLProtocol.responseHeaders = [:]
        super.tearDown()
    }

    func testSafetyPrecedesCredentialsAndNetworkForEveryTrigger() async {
        var networkCalls = 0
        StubURLProtocol.handler = { _ in networkCalls += 1; return (200, Data()) }
        let service = GeminiService(configuration: .init(apiKey: ""), session: session)
        for trigger in SafetyInterceptor.triggerWords {
            do {
                _ = try await service.generateReply(messages: [.init(role: .user, content: "I said \(trigger.uppercased())")], systemPrompt: "test")
                XCTFail("Expected a crisis interception")
            } catch { XCTAssertEqual(error as? SafetyError, .crisisDetected) }
        }
        XCTAssertEqual(networkCalls, 0)
    }

    func testRequestEncodesSystemHistoryHeaderAndExactDefaultEndpoint() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-only-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            var bodyData = request.httpBody
            if bodyData == nil, let stream = request.httpBodyStream {
                stream.open(); defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 4096)
                var data = Data()
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count <= 0 { break }
                    data.append(buffer, count: count)
                }
                bodyData = data
            }
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(bodyData)) as? [String: Any])
            let generation = try XCTUnwrap(body["generationConfig"] as? [String: Any])
            XCTAssertEqual(generation["maxOutputTokens"] as? Int, 4096)
            XCTAssertEqual((generation["thinkingConfig"] as? [String: String])?["thinkingLevel"], "LOW")
            let contents = try XCTUnwrap(body["contents"] as? [[String: Any]])
            XCTAssertEqual(contents.compactMap { $0["role"] as? String }, ["user", "model", "user"])
            let instruction = try XCTUnwrap(body["systemInstruction"] as? [String: Any])
            let parts = try XCTUnwrap(instruction["parts"] as? [[String: String]])
            XCTAssertEqual(parts.first?["text"], "system with local grounding")
            return (200, Data(#"{"candidates":[{"content":{"parts":[{"text":"hidden","thought":true},{"text":"A gentle reply."}]},"finishReason":"STOP"}]}"#.utf8))
        }
        let service = GeminiService(configuration: .init(apiKey: "test-only-key"), session: session)
        let reply = try await service.generateReply(messages: [
            .init(role: .user, content: "Hello"), .init(role: .assistant, content: "Welcome"),
            .init(role: .user, content: "I feel stressed")
        ], systemPrompt: "system with local grounding")
        XCTAssertEqual(reply, "A gentle reply.")
    }

    func testHTTPUnavailableModelAndSafetyBlockedAndMalformedResponses() async {
        let service = GeminiService(configuration: .init(apiKey: "test-only-key"), session: session)
        let cases: [(Int, String, GeminiError)] = [
            (404, "{}", .modelUnavailable("gemini-3.6-flash")),
            (410, "{}", .modelUnavailable("gemini-3.6-flash")), (429, "{}", .httpStatus(429)),
            (200, #"{"promptFeedback":{"blockReason":"SAFETY"}}"#, .responseBlocked),
            (200, #"{"candidates":[{"finishReason":"SAFETY"}]}"#, .responseBlocked),
            (200, #"{"candidates":[]}"#, .emptyResponse),
            (200, "not json", .invalidResponse)
        ]
        for (status, body, expected) in cases {
            StubURLProtocol.handler = { _ in (status, Data(body.utf8)) }
            do {
                _ = try await service.generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
                XCTFail("Expected \(expected)")
            } catch { XCTAssertEqual(error as? GeminiError, expected) }
        }
    }


    func testTransientFailureRetriesSameTurnThenSucceeds() async throws {
        var calls = 0
        var waits: [UInt64] = []
        StubURLProtocol.handler = { _ in
            calls += 1
            return calls < 3 ? (503, Data()) :
                (200, Data(#"{"candidates":[{"content":{"parts":[{"text":"Welcome back."}]},"finishReason":"STOP"}]}"#.utf8))
        }
        let service = GeminiService(configuration: .init(apiKey: "test"), session: session,
                                    sleep: { waits.append($0) })
        let reply = try await service.generateReply(messages: [.init(role: .user, content: "Hello")], systemPrompt: "test")
        XCTAssertEqual(reply, "Welcome back.")
        XCTAssertEqual(calls, 3)
        XCTAssertEqual(waits.count, 2)
        XCTAssertTrue((1_000_000_000...1_250_000_000).contains(waits[0]))
        XCTAssertTrue((2_000_000_000...2_250_000_000).contains(waits[1]))
    }

    func testServerRetriesStopAfterThreeAttempts() async {
        var calls = 0
        StubURLProtocol.handler = { _ in calls += 1; return (503, Data()) }
        let service = GeminiService(configuration: .init(apiKey: "test"), session: session, sleep: { _ in })
        do {
            _ = try await service.generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
            XCTFail("Expected exhausted service failure")
        } catch { XCTAssertEqual(error as? GeminiError, .httpStatus(503)) }
        XCTAssertEqual(calls, 3)
    }

    func testQuotaAndClientErrorsDoNotRetry() async {
        for status in [400, 401, 403, 404, 410, 429] {
            var calls = 0
            StubURLProtocol.handler = { _ in calls += 1; return (status, Data()) }
            let service = GeminiService(configuration: .init(apiKey: "test"), session: session,
                                        sleep: { _ in XCTFail("Client errors must not back off") })
            do {
                _ = try await service.generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
                XCTFail("Expected failure")
            } catch { XCTAssertEqual(calls, 1) }
        }
    }

    func testRetryAfterAndCancellationDuringBackoff() async {
        var calls = 0
        StubURLProtocol.handler = { _ in calls += 1; return (503, Data()) }
        StubURLProtocol.responseHeaders = ["Retry-After": "4"]
        let service = GeminiService(configuration: .init(apiKey: "test"), session: session, sleep: { delay in
            XCTAssertEqual(delay, 4_000_000_000)
            throw CancellationError()
        })
        do {
            _ = try await service.generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(calls, 1)
    }

    func testLongOrInvalidServerCooldownDoesNotRetry() async {
        for value in ["120", "nan", "inf"] {
            var calls = 0
            StubURLProtocol.handler = { _ in calls += 1; return (503, Data()) }
            StubURLProtocol.responseHeaders = ["Retry-After": value]
            let service = GeminiService(configuration: .init(apiKey: "test"), session: session,
                                        sleep: { _ in XCTFail("Must not wait on long or invalid cooldown") })
            do {
                _ = try await service.generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
                XCTFail("Expected service failure")
            } catch { XCTAssertEqual(error as? GeminiError, .httpStatus(503)) }
            XCTAssertEqual(calls, 1)
        }
    }

    func testTruncationRegeneratesOnceWithMoreRoomWithoutReturningPartialText() async throws {
        var limits: [Int] = []
        var histories: [[[String: Any]]] = []
        StubURLProtocol.handler = { request in
            let body = try Self.requestBody(request)
            let config = try XCTUnwrap(body["generationConfig"] as? [String: Any])
            limits.append(try XCTUnwrap(config["maxOutputTokens"] as? Int))
            histories.append(try XCTUnwrap(body["contents"] as? [[String: Any]]))
            let response = limits.count == 1
                ? #"{"candidates":[{"content":{"parts":[{"text":"Listen to me: It is"}]},"finishReason":"MAX_TOKENS"}]}"#
                : #"{"candidates":[{"content":{"parts":[{"text":"Choose one subject and study for five minutes."}]},"finishReason":"STOP"}]}"#
            return (200, Data(response.utf8))
        }
        let service = GeminiService(configuration: .init(apiKey: "test"), session: session)
        let reply = try await service.generateReply(messages: [.init(role: .user, content: "Three tests tomorrow")], systemPrompt: "test")
        XCTAssertEqual(reply, "Choose one subject and study for five minutes.")
        XCTAssertEqual(limits, [4096, 8192])
        XCTAssertEqual(histories.map(\.count), [1, 1])
        XCTAssertEqual((histories[0][0]["parts"] as? [[String: String]])?.first?["text"],
                       (histories[1][0]["parts"] as? [[String: String]])?.first?["text"])
    }

    func testPersistentTruncationFailsExplicitlyWithoutAcceptingAnUnfinishedReply() async {
        var calls = 0
        StubURLProtocol.handler = { _ in
            calls += 1
            return (200, Data(#"{"candidates":[{"finishReason":"MAX_TOKENS"}]}"#.utf8))
        }
        do {
            _ = try await GeminiService(configuration: .init(apiKey: "test"), session: session)
                .generateReply(messages: [.init(role: .user, content: "Hello")], systemPrompt: "test")
            XCTFail("Truncated output must not be treated as a complete response")
        } catch { XCTAssertEqual(error as? GeminiError, .outputTruncated) }
        XCTAssertEqual(calls, 2)
    }

    func testExplicitModelOverrideDoesNotReceiveUnsupportedThinkingConfiguration() async throws {
        StubURLProtocol.handler = { request in
            let body = try Self.requestBody(request)
            let config = try XCTUnwrap(body["generationConfig"] as? [String: Any])
            XCTAssertNil(config["thinkingConfig"])
            return (200, Data(#"{"candidates":[{"content":{"parts":[{"text":"Hello."}]},"finishReason":"STOP"}]}"#.utf8))
        }
        _ = try await GeminiService(configuration: .init(apiKey: "test", model: "custom-model"), session: session)
            .generateReply(messages: [.init(role: .user, content: "Hello")], systemPrompt: "test")
    }

    private static func requestBody(_ request: URLRequest) throws -> [String: Any] {
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            var bytes = Data()
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                bytes.append(buffer, count: count)
            }
            data = bytes
        }
        return try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(data)) as? [String: Any])
    }

    func testModelConfigurationNormalizesResourceNamesAndEmptyOverrides() {
        XCTAssertEqual(GeminiConfiguration(apiKey: "test").model, "gemini-3.6-flash")
        XCTAssertEqual(GeminiConfiguration(apiKey: "test", model: " \n").model, "gemini-3.6-flash")
        XCTAssertEqual(GeminiConfiguration(apiKey: "test", model: " models/gemini-3.5-flash-lite ").model,
                       "gemini-3.5-flash-lite")
    }

    func testInvalidModelDoesNotSend() async {
        StubURLProtocol.handler = { _ in XCTFail("Invalid model must not make a request"); return (200, Data()) }
        do {
            _ = try await GeminiService(configuration: .init(apiKey: "test", model: "../invalid"), session: session)
                .generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
            XCTFail("Expected invalid configuration")
        } catch { XCTAssertEqual(error as? GeminiError, .invalidConfiguration) }
    }

    func testMissingKeyDoesNotSendAndOverrideIsExplicit() async {
        StubURLProtocol.handler = { _ in XCTFail("Missing key must not make a request"); return (200, Data()) }
        let config = GeminiConfiguration(apiKey: "  ", model: "my-explicit-model")
        XCTAssertEqual(config.model, "my-explicit-model")
        do {
            _ = try await GeminiService(configuration: config, session: session)
                .generateReply(messages: [.init(role: .user, content: "Hi")], systemPrompt: "test")
            XCTFail("Expected missing key")
        } catch { XCTAssertEqual(error as? GeminiError, .missingAPIKey) }
    }
}
