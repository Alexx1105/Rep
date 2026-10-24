import XCTest
import Combine
import SwiftUI
import UIKit
import ActivityKit
import KimchiKit
@testable import Rep

@MainActor
private final class WaveformInputs: ObservableObject {
    @Published var level: Double = 0.2
    @Published var paused = false
    @Published var recording = true
}

private struct WaveformHost: View {
    @ObservedObject var inputs: WaveformInputs
    let expanded: Bool
    var body: some View {
        Group {
            if expanded {
                LiveActivityWaveformExpanded(audioLevel: inputs.level, isRecording: inputs.recording, isPaused: inputs.paused)
            } else {
                LiveActivityWaveformMinimal(audioLevel: inputs.level, isRecording: inputs.recording, isPaused: inputs.paused)
            }
        }.frame(width: 240, height: 100).background(.black)
    }
}

@MainActor
final class LiveActivityFlowDiagnosticTests: XCTestCase {
    func testSerialPushesAt300MillisecondsReachActivityState() async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw XCTSkip("Live Activities disabled") }
        let start = Date()
        let manager = AudioTranscriptionManager.shared
        let saved = (manager.isTranscribing, manager.didStopAudioStream, manager.audioLevels)
        defer {
            manager.isTranscribing = saved.0
            manager.didStopAudioStream = saved.1
            manager.audioLevels = saved.2
        }
        try await startTranscriptionLiveActivity(isRecording: true, isPaused: false, audioLevel: 0, startedAt: start)
        let activity = try XCTUnwrap(Activity<TranscriptionLiveActivityAttributes>.activities.first {
            abs($0.content.state.startedAt.timeIntervalSince(start)) < 0.01
        })
        manager.isTranscribing = true
        manager.didStopAudioStream = false
        var timings: [Double] = []
        var mismatches = 0
        for index in 0..<40 {
            let level: CGFloat = index.isMultiple(of: 2) ? 0.2 : 0.9
            manager.audioLevels = level
            let sent = Date()
            try await LocalLiveActivityManager.shared.pushLiveActivity(start)
            for _ in 0..<20 where abs(activity.content.state.audioLevel - level) > 0.0001 {
                try await Task.sleep(for: .milliseconds(25))
            }
            timings.append(Date().timeIntervalSince(sent))
            if abs(activity.content.state.audioLevel - level) > 0.0001 { mismatches += 1 }
            XCTAssertTrue(activity.content.state.isRecording)
            XCTAssertFalse(activity.content.state.isPaused)
            try await Task.sleep(for: .milliseconds(300))
        }
        await activity.end(nil, dismissalPolicy: .immediate)
        XCTAssertEqual(mismatches, 0, "Submitted levels did not reach Activity.content.state")
        let result = "40 submissions; mismatches=\(mismatches); mean completion ms=\(timings.reduce(0,+)/Double(timings.count)*1000); max completion ms=\((timings.max() ?? 0)*1000). Measures ActivityKit state, not Dynamic Island frames."
        print("DIAGNOSTIC: \(result)")
        let attachment = XCTAttachment(string: result)
        attachment.name = "ActivityKit update timings"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testExpandedBarsRespondToUpdatesAndStayStillWithoutUpdates() async throws {
        try await checkRendering(expanded: true)
    }

    func testCompactBarsRespondToUpdatesAndStayStillWithoutUpdates() async throws {
        try await checkRendering(expanded: false)
    }

    private func checkRendering(expanded: Bool) async throws {
        let inputs = WaveformInputs()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 240, height: 100)
        let host = UIHostingController(rootView: WaveformHost(inputs: inputs, expanded: expanded))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        func frame() async throws -> Data {
            try await Task.sleep(for: .milliseconds(400))
            host.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: host.view.bounds)
            return try XCTUnwrap(renderer.image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }.pngData())
        }
        let low = try await frame()
        inputs.level = 0.9
        let high = try await frame()
        XCTAssertNotEqual(low, high, "Audio-level update must change the waveform")
        let unchanged = try await frame()
        XCTAssertEqual(high, unchanged, "No timeline-driven movement should remain")
        inputs.level = 0.2
        let returned = try await frame()
        XCTAssertEqual(low, returned, "Returning to the same level should restore bar heights")
        inputs.paused = true
        let paused = try await frame()
        inputs.level = 0.9
        let pausedHigh = try await frame()
        XCTAssertEqual(paused, pausedHigh, "Paused bars must ignore audio-level changes")
        inputs.paused = false
        inputs.recording = false
        let stopped = try await frame()
        XCTAssertEqual(paused, stopped, "Stopped and paused bars should use idle heights")
        inputs.recording = true
        inputs.level = 0
        let silent = try await frame()
        inputs.level = 0.03
        let threshold = try await frame()
        XCTAssertEqual(silent, threshold, "Existing low-level clamp must remain unchanged")
    }
}

// Exact waveform structs from the edited widget source.
struct LiveActivityWaveformExpanded: View {
    let audioLevel: Double
    let isRecording: Bool
    let isPaused: Bool
    
    private let multipliers: [Double] = [0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65, 0.18]
    
    var body: some View {
        let isActive = isRecording && !isPaused
        let level = min(max(audioLevel, 0.12), 1.0)
        let curve = isActive ? 0.25 + (level * 0.75) : 0.0

        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<9, id: \.self) { index in
                let idleHeight = 21.0
                let height = isActive ? idleHeight + multipliers[index] * 24.0 * curve : idleHeight

                Capsule()
                    .frame(width: 10, height: height)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(height: 42, alignment: .center)
        .animation(.easeInOut(duration: 0.2), value: audioLevel)
    }
}

struct LiveActivityWaveformMinimal: View {
    let audioLevel: Double
    let isRecording: Bool
    let isPaused: Bool
    
    
    private let multipliers: [Double] = [0.15, 0.55, 0.95, 0.35, 0.75]
    
    var body: some View {
        let isActive = isRecording && !isPaused
        let level = min(max(audioLevel, 0.12), 1.0)
        let curve = isActive ? 0.25 + (level * 0.75) : 0.0
        
        HStack(alignment: .center, spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                let idleHeight = 4.0
                let height = isActive ? idleHeight + multipliers[index] * 24.0 * curve : idleHeight
                
                Capsule()
                    .frame(width: 2, height: height)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: audioLevel)
    }
}


