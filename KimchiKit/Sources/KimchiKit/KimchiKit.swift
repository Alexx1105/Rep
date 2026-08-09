import ActivityKit
import Foundation


private enum DynamicRepError: Error {
    case activitiesDisabled
}

@available(iOS 17.0, *)
public struct DynamicRepAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        public var plainText: String
        public var userContentPage: [String]
        
        enum CodingKeys: String, CodingKey {
            case plainText = "plain_text"
            case userContentPage
        }
        
        public init(plainText: String, userContentPage: [String]) {
            self.plainText = plainText
            self.userContentPage = userContentPage
        }
    }
    
    public var activityID: String   ///future use (maybe)
    
    public init(activityID: String) {
        self.activityID = activityID
    }
}


@available(iOS 18.0, *)
public struct IntervalLiveActivityAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        public var plainText: String
        public var selectedInterval: String
        
        public init(plainText: String, selectedInterval: String) {
            self.plainText = plainText
            self.selectedInterval = selectedInterval
        }
    }
    
    public init() {}
}


@available(iOS 18.0, *)
public struct TranscriptionLiveActivityAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        public var isRecording: Bool
        public var isPaused: Bool
        
        public var audioLevel: CGFloat
        public var startedAt: Date
        
        public init(isRecording: Bool, isPaused: Bool, audioLevel: CGFloat, startedAt: Date) {
            self.isRecording = isRecording
            self.isPaused = isPaused
            self.audioLevel = audioLevel
            self.startedAt = startedAt
        }
    }
    public init() {}
}



@available(iOS 18.0, *)
public actor IntervalLiveActivityUpdateManager {
    public static let shared = IntervalLiveActivityUpdateManager()
    
    nonisolated(unsafe) ///manually syncronize to prevent data race
    private var activity: Activity<IntervalLiveActivityAttributes>?
    
    public func setActivity(activity: Activity<IntervalLiveActivityAttributes>) {
        self.activity = activity
    }
    
    
    public func update(label: String, title: String) async {
        guard let activity else { return }
        
        let state = IntervalLiveActivityAttributes.ContentState(plainText: title, selectedInterval: label)
        await activity.update(ActivityContent(state: state, staleDate: nil, relevanceScore: 1.0), alertConfiguration: .init(title: "", body: "", sound: .default))
        
        print("Live Activity updated ✅: \(label)")
    }
}


@available(iOS 18.0, *)
public actor TranscriptionLiveActivityManager {
    public static let shared = TranscriptionLiveActivityManager()
    
    nonisolated(unsafe)
    private var activity: Activity<TranscriptionLiveActivityAttributes>?
    
    public func setActivity(activity: Activity<TranscriptionLiveActivityAttributes>) {
        self.activity = activity
    }
    
    public func update(isRecording: Bool, isPaused: Bool, audioLevel: CGFloat, startedAt: Date) async throws {
        guard let activity else { return }
        
        let state = TranscriptionLiveActivityAttributes.ContentState(isRecording: isRecording, isPaused: isPaused, audioLevel: audioLevel, startedAt: startedAt)
        await activity.update(ActivityContent(state: state, staleDate: nil, relevanceScore: 1.0), alertConfiguration: nil)
        
        print("Live Activity updated ✅")
    }
}



@available(iOS 18.0, *)
public func startIntervalActivity(label: String, title: String) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    Task {
        do {
            let attributes = IntervalLiveActivityAttributes()
            let state = IntervalLiveActivityAttributes.ContentState(plainText: title, selectedInterval: label)
            
            let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil, relevanceScore: 1.0), pushType: nil, style: .transient)
            
            await IntervalLiveActivityUpdateManager.shared.setActivity(activity: activity)
            print("Live Activity started 🔄")
            
        } catch {
            print("Failed to start Live Activity ❌:", error.localizedDescription)
        }
        try await Task.sleep(for: .seconds(7))
        for activity in Activity<IntervalLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .default)
            print("activity ended")
        }
    }
}


@available(iOS 18.0, *)
public func updateIntervalActivity(label: String, title: String) async {
    await IntervalLiveActivityUpdateManager.shared.update(label: label, title: title)
}



@available(iOS 18.0, *)
public func debugStartIntervalLiveActivity() {          ///for manaully debugging/changing UI
    startIntervalActivity(label: "10m", title: "Debug Mode 🧪")
}



@available(iOS 18.0, *)
public func startTranscriptionLiveActivity(isRecording: Bool, isPaused: Bool, audioLevel: CGFloat, startedAt: Date) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    Task {
        do {
            let attributes = TranscriptionLiveActivityAttributes()
            let state = TranscriptionLiveActivityAttributes.ContentState(isRecording: isRecording, isPaused: isPaused, audioLevel: audioLevel, startedAt: startedAt)
            
            let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil, relevanceScore: 1.0), pushType: nil, style: .transient)
            
            await TranscriptionLiveActivityManager.shared.setActivity(activity: activity)
            print("Live Activity started 🔄")
            
        } catch {
            print("Failed to start Live Activity ❌:", error.localizedDescription)
        }
    }
}


@available(iOS 18.0, *)
public func updateTranscriptionLiveActivity(isRecording: Bool, isPaused: Bool, audioLevel: CGFloat, startedAt: Date) async throws {
    do {
        try await TranscriptionLiveActivityManager.shared.update(isRecording: isRecording, isPaused: isPaused, audioLevel: audioLevel, startedAt: startedAt)
        print("successfully updated transcription live activity")
    } catch {
        print("error updting transcription live activity", error.localizedDescription)
    }
}



@available(iOS 18.0, *)
public func debugTranscriptionLiveActivity() {          ///for manaully debugging/changing UI
    startIntervalActivity(label: "10m", title: "Debug Mode 🧪")
}


