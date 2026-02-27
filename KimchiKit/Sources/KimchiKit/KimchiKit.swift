import ActivityKit


import ActivityKit

@available(iOS 17.0, *)
public struct DynamicRepAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        
        public var plainText: String
        public var userContentPage: [String]
        
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



@available(iOS 17.0, *)
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



@available(iOS 17.0, *)
public actor LiveActivityUpdateManager {
    
    public static let shared = LiveActivityUpdateManager()
    
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
public func startIntervalActivity(label: String, title: String) {
    
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    Task {
        do {
            let attributes = IntervalLiveActivityAttributes()
            let state = IntervalLiveActivityAttributes.ContentState(plainText: title, selectedInterval: label)
            
            let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil, relevanceScore: 1.0), pushType: nil, style: .transient)
            
            await LiveActivityUpdateManager.shared.setActivity(activity: activity)
            print("Live Activity started 🔄")
            
        } catch {
            print("Failed to start Live Activity ❌:", error.localizedDescription)
        }
    }
}

@available(iOS 17.0, *)
public func updateIntervalActivity(label: String, title: String) async {
    
    await LiveActivityUpdateManager.shared.update(label: label, title: title)
}



@available(iOS 18.0, *)
public func debugStartIntervalLiveActivity() {          ///for manaully debugging/changing UI
    startIntervalActivity(label: "10m", title: "Debug Mode 🧪")
}
