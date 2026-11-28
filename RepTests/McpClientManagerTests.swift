import Foundation
import Supabase
import Testing
@testable import Rep

@MainActor
struct McpClientManagerTests {
    private func payload(title: String? = "Test note", content: String = "REP-MCP-UNIT-TEST") -> [String: AnyJSON] {
        var record: [String: AnyJSON] = [
            "source": .string("gpt-mcp"),
            "content": .string(content),
            "format": .string("plain"),
            "sent_at": .string("2026-11-28T16:00:00Z")
        ]
        if let title { record["title"] = .string(title) }
        return record
    }

    private func stream(_ messages: [[String: AnyJSON]]) -> AsyncStream<[String: AnyJSON]> {
        AsyncStream { continuation in
            for message in messages { continuation.yield(message) }
            continuation.finish()
        }
    }

    @Test func emptyStreamCompletes() async throws {
        try await McpClientManager().decodeServerPayload(broadcast: stream([]))
    }

    // These fixtures use the expected server wire format, including sent_at.
    // A thrown decoding error is a failure, not an expected success.
    @Test func acceptsPlainNoteWithSnakeCaseTimestamp() async throws {
        try await McpClientManager().decodeServerPayload(broadcast: stream([payload()]))
    }

    @Test func acceptsMissingOptionalTitle() async throws {
        try await McpClientManager().decodeServerPayload(broadcast: stream([payload(title: nil)]))
    }

    @Test func acceptsMarkdownAndUnicode() async throws {
        var note = payload(content: "# Notes\n\n- Café ☕️\n- 你好")
        note["format"] = .string("markdown")
        try await McpClientManager().decodeServerPayload(broadcast: stream([note]))
    }

    @Test func acceptsMultipleNotesInOneStream() async throws {
        try await McpClientManager().decodeServerPayload(broadcast: stream([
            payload(content: "FIRST"), payload(content: "SECOND")
        ]))
    }

    @Test func missingRequiredContentThrowsDecodingError() async {
        var note = payload()
        note.removeValue(forKey: "content")
        await #expect(throws: DecodingError.self) {
            try await McpClientManager().decodeServerPayload(broadcast: stream([note]))
        }
    }

    @Test func numericContentThrowsDecodingError() async {
        var note = payload()
        note["content"] = .integer(42)
        await #expect(throws: DecodingError.self) {
            try await McpClientManager().decodeServerPayload(broadcast: stream([note]))
        }
    }
}
