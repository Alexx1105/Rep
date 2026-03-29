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


extension MainBlockBody {
    static func joinContent(_ c: [MainBlockBody.RichText]) -> String {
        c.map{ $0.text?.content ?? "" }.joined()
    }
}

//@MainActor
// func fetchSyncPg(pageID: String, context: ModelContext) throws -> NotionPageMetaData? {          ///query synced page
//   let fetchSyncPg = FetchDescriptor<NotionPageMetaData>(predicate: #Predicate {$0.pageID == pageID})
//   print("all ids: \(pageID)")
//   return try context.fetch(fetchSyncPg).first
//}

@MainActor
public func fetchPg(pageID: String, context: ModelContext) throws -> UserPageTitle? {                     ///query un-synced page
   let fetchPg = FetchDescriptor<UserPageTitle>(predicate: #Predicate { $0.titleID == pageID })
   return try context.fetch(fetchPg).first
}


public func generatePushToken() async -> String {
    
    let liveActvityToken = await Activity<DynamicRepAttributes>.pushToStartTokenUpdates.first(where: {_ in true })
    guard let token = liveActvityToken else { return "" }
    
    let tokenHex: String? = liveActvityToken?.map{String(format: "%02x", $0)}.joined()
    print("push token hex: \(tokenHex ?? "")")
    
    guard let pushToken: String = tokenHex else { return "" }
    return pushToken
}
