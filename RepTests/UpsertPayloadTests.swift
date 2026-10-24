import XCTest
import Foundation
import CryptoKit
@testable import Rep

@MainActor
final class UpsertPayloadTests: XCTestCase {
    private let page = "upsert-diagnostic-" + UUID().uuidString
    private let token = "diagnostic-not-a-real-push-token"
    private let title = "Upsert diagnostic"
    private let note = "Synthetic note with unicode café and a quotation \"test\"."
    private var contentHash: String { SHA256.hash(data: Data(note.utf8)).map { String(format: "%02x", $0) }.joined() }

    func testTranscriptionPayloadUsesPageID() throws {
        try check(PushToSupabaseTranscriptionNotes(token: token, pageID: page, title: title,
                                                   fullNotes: note, contentHash: contentHash), name: "transcription")
    }

    func testNotionPayload() throws {
        try check(PushToSupabaseNotion(token: token, page_data: note, page_id: page,
                                      page_title: title, content_hash: contentHash), name: "notion")
    }

    func testOpenAIPayload() throws {
        try check(PushToSupabaseOpenAi(token: token, openaiID: page, title: title,
                                      content: note, contentHash: contentHash), name: "openai")
    }

    func testObsidianPayload() throws {
        try check(PushToSupabaseObsidian(token: token, pageID: page, title: title,
                                        content: note, contentHash: contentHash), name: "obsidian")
    }

    func testGoogleDocsPayload() throws {
        try check(PushToSupabaseGoogleDocs(token: token, pageID: page, title: title,
                                          content: note, contentHash: contentHash), name: "google")
    }

    func testTranscriptionRejectsMissingRequiredFieldsBeforeNetworking() async {
        let manager = SupabaseClientManager.shared
        for values in [("", title, note), (page, "", note), (page, title, "")] {
            for source in ["shared", "mobile", "desktop"] {
                do {
                    switch source {
                    case "shared":
                        try await manager.supabaseAudioTranscriptionNotesUpsert(pageID: values.0,
                              title: values.1, fullNotes: values.2, token: token)
                    case "mobile":
                        try await manager.upsertRepMobileNotes(fullNotes: values.2, pageID: values.0, title: values.1)
                    default:
                        try await manager.upsertRepDesktopNotes(fullNotes: values.2, pageID: values.0, title: values.1)
                    }
                    XCTFail("\(source) accepted a missing required field")
                } catch ErrorDesc.nilValue {
                    // Expected: no push token generation or network request.
                } catch {
                    XCTFail("\(source) threw an unexpected error: \(error)")
                }
            }
        }
    }

    private func check<T: Encodable>(_ payload: T, name: String) throws {
        let encoded = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: String])
        XCTAssertEqual(Set(object.keys), ["token", "page_id", "page_title", "page_data", "content_hash"])
        XCTAssertEqual(object["page_id"], page)
        XCTAssertEqual(object["page_data"], note)
        XCTAssertEqual(object["page_title"], title)
        XCTAssertEqual(object["token"], token)
        XCTAssertEqual(object["content_hash"], contentHash)
        XCTAssertNil(object["user_id"])
        let attachment = XCTAttachment(data: encoded, uniformTypeIdentifier: "public.json")
        attachment.name = "upsert-payload-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
