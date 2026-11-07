/* Global PushTokenManger class handles
   the caching, updating, and initial
   creation of push tokens */
import Foundation
import ActivityKit
import KimchiKit
import Supabase


public final class PushTokenManager {

    @MainActor
    static func cacheInitialPushToken(_ token: String) async {
        guard !token.isEmpty else { return }

        do {
            let session = try await supabaseDBClient.auth.session
            let tokenStorageKey = "push.lastSyncedToken.\(session.user.id.uuidString)"
            
            guard UserDefaults.standard.object(forKey: tokenStorageKey) == nil else { return }
            UserDefaults.standard.set(token, forKey: tokenStorageKey)
            
        } catch {
            print("failed to cache initial push token:", ErrorDesc.pushTokenError, error)
        }
    }

    
    public static func generatePushToken() async -> String {
        let liveActvityToken = await Activity<DynamicRepAttributes>.pushToStartTokenUpdates.first(where: {_ in true })
        guard liveActvityToken != nil else { return "" }
        
        let tokenHex: String = liveActvityToken!.map{String(format: "%02x", $0)}.joined()
        print("push token hex: \(tokenHex)")
        
        return tokenHex
    }
    
    
    var task: Task<Void, Never>?
    public func updatePushTokenListener(previousToken: String) async throws {
        
        guard !previousToken.isEmpty else { throw ErrorDesc.nilValue }
        guard task == nil else { return }
        
        task = Task {
            var previousTokenHex: String = previousToken
            for await updateLiveActivityToken in Activity<DynamicRepAttributes>.pushToStartTokenUpdates {
                
                let updatedTokenHex: String = updateLiveActivityToken.map{ String(format: "%02x", $0) }.joined()
                guard !updatedTokenHex.isEmpty, updatedTokenHex != previousTokenHex else { continue }
                
                while !Task.isCancelled {
                    do {
                        _ = try await supabaseDBClient.from("push_tokens_dev").update(PushTokenUpdate(token: updatedTokenHex)).eq("token", value: previousTokenHex).execute()
                        previousTokenHex = updatedTokenHex
                        
                        let session = try await supabaseDBClient.auth.session
                        let tokenStorageKey: String = "push.lastSyncedToken.\(session.user.id.uuidString)"
                        UserDefaults.standard.set(updatedTokenHex, forKey: tokenStorageKey)
                        break
                        
                    } catch {
                        print("failed to update push token:", ErrorDesc.pushTokenError, error)
                    }
                    
                    do {
                        try await Task.sleep(for: .seconds(3))
                    } catch {
                        return
                    }
                }
            }
        }
    }
}
