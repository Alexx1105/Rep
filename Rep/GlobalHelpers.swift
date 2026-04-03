//
//  GlobalHelpers.swift
//  Rep
//
//  Created by alex haidar on 3/13/26.
//TODO: move all global helper functions and extensions across the code base into here

import Foundation
import SwiftData
import ActivityKit
import KimchiKit

//@MainActor
// func fetchSyncPg(pageID: String, context: ModelContext) throws -> NotionPageMetaData? {          ///query synced page
//   let fetchSyncPg = FetchDescriptor<NotionPageMetaData>(predicate: #Predicate {$0.pageID == pageID})
//   print("all ids: \(pageID)")
//   return try context.fetch(fetchSyncPg).first
//}


final class GlobalHelpers {
    
    
    static public func fetchAuthToken() throws -> String {
        let context = OAuthTokens.shared.modelContext
        let fetchDescriptor = FetchDescriptor<AuthToken>()
        let authToken = try context?.fetch(fetchDescriptor)
        
        guard let token = authToken?.first?.accessToken else { throw ErrorDesc.authTokenError }
        return token
    }
    
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
