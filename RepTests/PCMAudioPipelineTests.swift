import XCTest
import Foundation
import Combine
import SwiftUI
import UIKit
import ActivityKit
@preconcurrency import AVFoundation
import KimchiKit
@testable import Rep

@MainActor
private final class PCMLevel: ObservableObject {
    @Published var value: Double = 0
}

private struct PCMDrivenWaveforms: View {
    @ObservedObject var level: PCMLevel
    var body: some View {
        VStack(spacing: 0) {
            LiveActivityWaveformExpanded(audioLevel: level.value, isRecording: true, isPaused: false)
                .frame(width: 240, height: 100)
            LiveActivityWaveformMinimal(audioLevel: level.value, isRecording: true, isPaused: false)
                .frame(width: 240, height: 100)
        }.background(.black)
    }
}

@MainActor
final class PCMAudioPipelineTests: XCTestCase {
    private let amplitudes: [Float] = [0, 0.001, 0.003, 0.006, 0.012, 0.025, 0.05, 0.2]

    private func convert(amplitude: Float, frames: AVAudioFrameCount = 4800) throws -> AudioBufferData {
        let inputFormat = try XCTUnwrap(AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                sampleRate: 48_000, channels: 1, interleaved: false))
        let input = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frames))
        input.frameLength = frames
        let samples = try XCTUnwrap(input.floatChannelData)[0]
        for index in 0..<Int(frames) {
            samples[index] = amplitude * sin(2 * Float.pi * 1000 * Float(index) / 48_000)
        }
        let outputFormat = try XCTUnwrap(AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                sampleRate: 24_000, channels: 1, interleaved: false))
        let converter = try XCTUnwrap(AVAudioConverter(from: inputFormat, to: outputFormat))
        let output = try AudioTranscriptionHelper.resampleBuffer(input, converter: converter, outputFormat: outputFormat)
        XCTAssertGreaterThan(output.frameLength, 0, "Resampling produced no audio")
        let encoded = try AudioTranscriptionHelper.convertBufferToPCM16Data(output)
        XCTAssertEqual(encoded.data.count, Int(output.frameLength) * 2)
        return encoded
    }

    func testPCMBytesAgreeWithRMSAndScaledLevels() throws {
        for amplitude in amplitudes {
            let encoded = try convert(amplitude: amplitude)
            let byteRMS: Float = encoded.data.withUnsafeBytes { bytes in
                var squares: Float = 0
                for offset in stride(from: 0, to: bytes.count, by: 2) {
                    let integer = Int16(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: Int16.self))
                    let sample = Float(integer) / Float(Int16.max)
                    squares += sample * sample
                }
                return sqrt(squares / Float(bytes.count / 2))
            }
            XCTAssertEqual(byteRMS, encoded.rms, accuracy: 0.00004)
            let expectedRMS = amplitude / sqrt(2)
            XCTAssertEqual(encoded.rms, expectedRMS, accuracy: amplitude * 0.05 + 0.00001)
            let expectedLevel = min(expectedRMS * 25, 1)
            XCTAssertEqual(AudioTranscriptionHelper.scaleAudioWaves(rms: encoded.rms), expectedLevel,
                           accuracy: max(0.001, expectedLevel * 0.05))
        }
    }

    func testActual512FrameTapSizeProducesNonemptyPCM() throws {
        for amplitude in amplitudes {
            let encoded = try convert(amplitude: amplitude, frames: 512)
            XCTAssertGreaterThan(encoded.data.count, 0)
            if amplitude > 0 { XCTAssertGreaterThan(encoded.rms, 0) }
        }
    }

    func testPCMLevelsReachActivityKitAndChangeBothRenderedWaveforms() async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw XCTSkip("Live Activities disabled") }
        let started = Date()
        try await startTranscriptionLiveActivity(isRecording: true, isPaused: false, audioLevel: 0, startedAt: started)
        let activity = try XCTUnwrap(Activity<TranscriptionLiveActivityAttributes>.activities.first {
            abs($0.content.state.startedAt.timeIntervalSince(started)) < 0.01
        })
        let manager = AudioTranscriptionManager.shared
        let saved = (manager.audioLevels, manager.isTranscribing, manager.didStopAudioStream)
        defer {
            manager.audioLevels = saved.0
            manager.isTranscribing = saved.1
            manager.didStopAudioStream = saved.2
        }
        manager.isTranscribing = true
        manager.didStopAudioStream = false
        let inputs = PCMLevel()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 240, height: 200)
        let host = UIHostingController(rootView: PCMDrivenWaveforms(level: inputs))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        var expanded: [Data] = []
        var compact: [Data] = []
        var results: [[String: Double]] = []
        for amplitude in amplitudes + [0.025, 0] {
            let pcm = try convert(amplitude: amplitude, frames: 512)
            let scaled = AudioTranscriptionHelper.scaleAudioWaves(rms: pcm.rms)
            manager.audioLevels = CGFloat(scaled)
            let expected = scaled > 0.03 ? CGFloat(scaled) : 0
            try await LocalLiveActivityManager.shared.pushLiveActivity(started)
            for _ in 0..<20 where abs(activity.content.state.audioLevel - expected) > 0.0001 {
                try await Task.sleep(for: .milliseconds(25))
            }
            XCTAssertEqual(activity.content.state.audioLevel, expected, accuracy: 0.0001)
            // Feed the state read back from ActivityKit into exact copies of the
            // widget views. This host is not the system Dynamic Island renderer.
            inputs.value = Double(activity.content.state.audioLevel)
            try await Task.sleep(for: .milliseconds(350))
            host.view.layoutIfNeeded()
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }
            let bitmap = try XCTUnwrap(image.cgImage)
            expanded.append(try XCTUnwrap(UIImage(cgImage: XCTUnwrap(bitmap.cropping(to: CGRect(x: 0, y: 0, width: 240, height: 100)))).pngData()))
            compact.append(try XCTUnwrap(UIImage(cgImage: XCTUnwrap(bitmap.cropping(to: CGRect(x: 0, y: 100, width: 240, height: 100)))).pngData()))
            results.append(["amplitude": Double(amplitude), "rms": Double(pcm.rms),
                            "scaledLevel": Double(scaled), "activityLevel": Double(activity.content.state.audioLevel)])
        }
        await activity.end(nil, dismissalPolicy: .immediate)
        for frames in [expanded, compact] {
            XCTAssertEqual(frames[0], frames[1], "Sub-floor levels should share the existing idle shape")
            XCTAssertEqual(frames[1], frames[2], "Sub-floor levels should share the existing idle shape")
            XCTAssertNotEqual(frames[4], frames[5], "Moderate PCM changes must change bar heights")
            XCTAssertNotEqual(frames[5], frames[6], "Louder PCM must change bar heights")
            XCTAssertEqual(frames[5], frames[8], "Returning to the same amplitude must restore heights")
            XCTAssertEqual(frames[0], frames[9], "Silence must restore the initial shape")
        }
        let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: results, options: .prettyPrinted),
                                      uniformTypeIdentifier: "public.json")
        attachment.name = "PCM RMS and ActivityKit levels"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
