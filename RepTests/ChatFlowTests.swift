import Foundation
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import Rep

@Suite(.serialized)
@MainActor
struct ChatFlowTests {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: OpenAIChat.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func reset() {
        Chat.shared.chat = ""
        Chat.shared.chatID = UUID()
        Chat.shared.responseMessage = []
    }

    @Test
    func sidebarLoadsOnlyTheSelectedPage() throws {
        reset()
        defer { reset() }
        let store = try container()
        let pageID = UUID().uuidString
        store.mainContext.insert(OpenAIChat(content: "Selected notes", openaiId: pageID))
        store.mainContext.insert(OpenAIChat(content: "Other notes", openaiId: "other"))
        try store.mainContext.save()
        let selected = try #require(try Chat.loadSavedChat(pageID: pageID, context: store.mainContext))
        #expect(selected.openaiId == pageID)
        #expect(Chat.shared.chatID == UUID(uuidString: pageID))
        #expect(Chat.shared.responseMessage.map(\.id) == [pageID])
        #expect(Chat.shared.responseMessage.map(\.text) == ["Selected notes"])
    }

    @Test
    func missingPageLeavesTheCurrentChatIntact() throws {
        reset()
        defer { reset() }
        let store = try container()
        Chat.shared.responseMessage = [.init(id: "current", text: "Current notes")]
        let selected = try Chat.loadSavedChat(pageID: "missing", context: store.mainContext)
        #expect(selected == nil)
        #expect(Chat.shared.responseMessage.map(\.text) == ["Current notes"])
    }

    @Test
    func reopeningReadsThePersistedRevision() throws {
        reset()
        defer { reset() }
        let store = try container()
        let saved = OpenAIChat(content: "Original notes", openaiId: "existing-page")
        store.mainContext.insert(saved)
        store.mainContext.insert(OpenAIChat(content: "Unchanged", openaiId: "other-page"))
        try store.mainContext.save()
        _ = try Chat.loadSavedChat(pageID: saved.openaiId, context: store.mainContext)
        // Tests storage/reopening only, not the live model-generation path.
        saved.content = "Revised notes"
        try store.mainContext.save()
        let freshContext = ModelContext(store)
        let selected = try #require(try Chat.loadSavedChat(pageID: saved.openaiId, context: freshContext))
        let menuRecords = try freshContext.fetch(FetchDescriptor<OpenAIChat>())
        #expect(selected.content == "Revised notes")
        #expect(menuRecords.count == 2)
        #expect(menuRecords.first { $0.openaiId == "other-page" }?.content == "Unchanged")
        #expect(Chat.shared.responseMessage.map(\.id) == ["existing-page"])
        #expect(Chat.shared.responseMessage.map(\.text) == ["Revised notes"])
    }

    @Test
    func emptyInputReturnsWithoutGenerationOrPersistence() async throws {
        reset()
        defer { reset() }
        let store = try container()
        Chat.shared.chat = " \n "
        var completed = false
        try await Chat.sendChatMessage(
            userFile: nil, context: store.mainContext, modelTier: .gptMini,
            selectedPhotos: [], onCreditsNeeded: { Issue.record("Unexpected billing callback") },
            onResponseComplete: { completed = true }
        )
        #expect(!completed)
        #expect(!Chat.shared.isSyncingChat)
        #expect(Chat.shared.responseMessage.isEmpty)
        #expect(try store.mainContext.fetchCount(FetchDescriptor<OpenAIChat>()) == 0)
    }

    @Test
    func streamBufferPreservesUnicodeAndTheLastShortChunk() async {
        let buffer = chatBuffer()
        let chunks = ["Study notes\n\n", "Café ", "☕️", "\n", "你好", "!"]
        for chunk in chunks { await buffer.append(chunk) }
        #expect(await buffer.chunkSnapshot() == chunks.joined())
    }

    @Test
    func cameraJPEGIsRecognizedAndWrappedInMultipart() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
        let jpeg = try #require(image.jpegData(compressionQuality: 0.85))
        #expect(guessMimeType(for: jpeg) == "image/jpeg")
        let body = try AIRequestManager.shared.buildPhotoBodyHelper(userPhotoData: jpeg, fileIdentifier: "test-boundary")
        #expect(body.starts(with: Data("--test-boundary\r\n".utf8)))
        #expect(body.range(of: Data("Content-Type: image/jpeg\r\n\r\n".utf8)) != nil)
        #expect(body.range(of: jpeg) != nil)
    }

    @Test
    func benchmarkActorBufferAgainstDirectAccumulation() async {
        let chunks = (0..<1200).map { "Fact \($0): a specific observation.\n\n" }
        var direct = ""
        let directStart = Date.timeIntervalSinceReferenceDate
        for chunk in chunks { direct += chunk }
        let directMs = (Date.timeIntervalSinceReferenceDate - directStart) * 1000
        let buffer = chatBuffer()
        let actorStart = Date.timeIntervalSinceReferenceDate
        for chunk in chunks { await buffer.append(chunk) }
        let buffered = await buffer.chunkSnapshot()
        let actorMs = (Date.timeIntervalSinceReferenceDate - actorStart) * 1000
        #expect(buffered == direct)
        print("CHAT_BENCH buffer chunks=1200 bytes=\(direct.utf8.count) directMs=\(directMs) actorMs=\(actorMs)")
    }

    @Test(arguments: [1, 10, 40])
    func benchmarkActualNoteRenderer(paragraphs: Int) throws {
        let text = (["Study Notes"] + (0..<paragraphs).map {
            "Observation \($0) describes one specific idea with supporting detail for the reader."
        }).joined(separator: "\n\n")
        var milliseconds: [Double] = []
        var height = 0.0
        // Actual reusable notes view, including SwiftUI layout. Offscreen
        // simulator rendering is not an onscreen frame-rate measurement.
        for _ in 0..<3 {
            let start = Date.timeIntervalSinceReferenceDate
            let renderer = ImageRenderer(content: AINotesContentView(text: text).frame(width: 350))
            renderer.scale = 1
            let rendered = try #require(renderer.uiImage)
            milliseconds.append((Date.timeIntervalSinceReferenceDate - start) * 1000)
            height = rendered.size.height
            #expect(rendered.size.width == 350)
            #expect(height > 0)
        }
        print("CHAT_BENCH renderer paragraphs=\(paragraphs) medianMs=\(milliseconds.sorted()[1]) height=\(height)")
    }

    @Test
    func benchmarkSelectingAnExistingChat() throws {
        reset()
        defer { reset() }
        let store = try container()
        for index in 0..<500 {
            store.mainContext.insert(OpenAIChat(content: "Notes \(index)", openaiId: "page-\(index)"))
        }
        try store.mainContext.save()
        let start = Date.timeIntervalSinceReferenceDate
        for _ in 0..<100 {
            let chat = try Chat.loadSavedChat(pageID: "page-499", context: store.mainContext)
            #expect(chat?.content == "Notes 499")
        }
        let milliseconds = (Date.timeIntervalSinceReferenceDate - start) * 1000
        print("CHAT_BENCH selection rows=500 selections=100 totalMs=\(milliseconds)")
    }
}
