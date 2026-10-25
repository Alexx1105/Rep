import XCTest
@preconcurrency import AVFoundation
@testable import Rep

@MainActor
final class AudioSessionActivationTests: XCTestCase {
    func testAsyncConfigurationUsesExistingCategoryAndMode() async throws {
        let session = AVAudioSession.sharedInstance()
        try await AudioTranscriptionManager.shared.configAudioSession()
        XCTAssertEqual(session.category, .playAndRecord)
        XCTAssertEqual(session.mode, .voiceChat)
        XCTAssertTrue(session.categoryOptions.contains(.defaultToSpeaker))
        XCTAssertTrue(session.categoryOptions.contains(.allowBluetoothHFP))
        XCTAssertGreaterThan(session.inputNumberOfChannels, 0)
        let deactivated = try await session.deactivate(options: [])
        XCTAssertTrue(deactivated)
    }

    func testCanReactivateAfterDeactivation() async throws {
        let session = AVAudioSession.sharedInstance()
        for _ in 0..<2 {
            try await AudioTranscriptionManager.shared.configAudioSession()
            XCTAssertGreaterThan(session.inputNumberOfChannels, 0)
            let deactivated = try await session.deactivate(options: [])
            XCTAssertTrue(deactivated)
        }
    }
}
