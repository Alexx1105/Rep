//
//  GlobalHelpers.swift
//  Rep
//
//  Created by alex haidar on 3/13/26.
//TODO: move all global helper functions across the code base into here 
import Foundation
import SwiftData


@MainActor
 func fetchSyncPg(pageID: String, context: ModelContext) throws -> NotionPageMetaData? {          ///query synced page
   let fetchSyncPg = FetchDescriptor<NotionPageMetaData>(predicate: #Predicate {$0.pageID == pageID})
   print("all ids: \(pageID)")
   return try context.fetch(fetchSyncPg).first
}

@MainActor
public func fetchPg(pageID: String, context: ModelContext) throws -> UserPageTitle? {                     ///query un-synced page
   let fetchPg = FetchDescriptor<UserPageTitle>(predicate: #Predicate { $0.titleID == pageID })
   return try context.fetch(fetchPg).first
}
