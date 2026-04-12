//
//  GlobalHelpers.swift
//  Rep
//
//  Created by alex haidar on 3/13/26.
import Foundation
import SwiftData
import ActivityKit
import KimchiKit
import Supabase



final class FetchAuth {
    static public func fetchAuthToken() throws -> String {
        let context = OAuthTokens.shared.modelContext
        let fetchDescriptor = FetchDescriptor<AuthToken>()
        let authToken = try context?.fetch(fetchDescriptor)
        
        guard let token = authToken?.first?.accessToken else { throw ErrorDesc.authTokenError }
        return token
    }
}


final class FetchSynced {
    static func fetchSyncPg(pageID: String, context: ModelContext) throws -> NotionPageMetaData? {             ///query synced page
        let fetchSyncPg = FetchDescriptor<NotionPageMetaData>(predicate: #Predicate {$0.pageID == pageID})
        print("all ids: \(pageID)")
        return try context.fetch(fetchSyncPg).first
    }
}

final class LastEdited: ObservableObject {
    @Published public var lastEdited: Date?
    static let shared = LastEdited()
}

final class FetchUnsynced {
    static public func fetchPg(pageID: String, context: ModelContext) throws -> UserPageTitle? {                     ///query un-synced page
        let fetchPg = FetchDescriptor<UserPageTitle>(predicate: #Predicate { $0.pageID == pageID })
        return try context.fetch(fetchPg).first
    }
}


public final class PushTokenManager {
    public static func generatePushToken() async -> String {
        let liveActvityToken = await Activity<DynamicRepAttributes>.pushToStartTokenUpdates.first(where: {_ in true })
        guard liveActvityToken != nil else { return "" }
        
        let tokenHex: String = liveActvityToken!.map{String(format: "%02x", $0)}.joined()
        print("push token hex: \(tokenHex)")
        
        return tokenHex
    }
}


public struct QueryExisting: Codable {
    let page_id: String
}

public final class PageDeletionManager {
    public static func checkExistingPageIDs(pageID: String) async -> [String] {                             ///deletion from the db, 
        do {
            let queryExistingIds: PostgrestResponse<[QueryExisting]> = try await supabaseDBClient.from("push_tokens").select("page_id").eq("page_id", value: pageID).execute()
            let result = queryExistingIds.value
            let ids = result.map{String($0.page_id)}
            print("IDs from query: \(ids)")
            return ids
            
        } catch {
            print("page deletion error ❗️:", ErrorDesc.supabaseQueryError, error)
            return ["no existing ids that match the incoming page"]
        }
    }
}
