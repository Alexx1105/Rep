//
//  LocalLiveActivityManager.swift
//  Rep
//
//  Created by alex haidar on 8/9/26.
//
/* stop, start, and update local LiveActivities here */
import Foundation
import ActivityKit
import KimchiKit


@MainActor
final class LocalLiveActivityManager {
    private init() {}
    
    
    static let shared = LocalLiveActivityManager()
    let audioManager = AudioTranscriptionManager.shared
    
    
    func startLiveActivity(_ startedAt: Date) {
        Task {
            do {
                startTranscriptionLiveActivity(isRecording: audioManager.isTranscribing, isPaused: false, audioLevel: audioManager.audioLevels, startedAt: startedAt)
                try await updateTranscriptionLiveActivity(isRecording: audioManager.isTranscribing, isPaused: audioManager.didStopAudioStream, audioLevel: audioManager.audioLevels, startedAt: startedAt)
                
                print("transcription live activity start successfully called in UI ✅")
            } catch {
                print("failed to start/update transcription live activity", ErrorDesc.callsiteError, error)
            }
        }
    }
    
    func pushLiveActivity(_ startedAt: Date) {
        Task {
            do {
                
                let liveActivityLevel = audioManager.audioLevels > 0.03 ? audioManager.audioLevels : 0.0  ///send 0.0 fallback to reset audio level freq
                try await updateTranscriptionLiveActivity(isRecording: audioManager.isTranscribing, isPaused: audioManager.didStopAudioStream, audioLevel: liveActivityLevel, startedAt: startedAt)
                
                print("transcription live activity update successfully called in UI ✅")
            } catch {
                print("failed to push audio bytes to live activity", ErrorDesc.callsiteError, error)
            }
        }
    }
    
    func stopLiveActivity() {
        Task {
            for activity in Activity<TranscriptionLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .default)
                print("successfully stopped live activity")
            }
        }
    }
}
