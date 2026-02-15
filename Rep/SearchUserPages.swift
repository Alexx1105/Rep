//
//  ImportUserPages.swift
//  MuscleMemory
//
//  Created by alex haidar on 12/8/24.
//

import Foundation
import SwiftData
import OSLog


public struct NotionSearchRequest: Codable {
    public let results: [result]
    public let object: String?
    
    public struct result: Codable {
        public let id: String?
        public let object: String?
        public let properties: properties?
        public let icon: Icon?
        public let last_edited_time: Date?
        public let created_time: Date?
    }
    
    public struct Icon: Codable {
        public let type: String?
        public let emoji: String?
    }
    
    public struct properties: Codable {
        public let title: TitleDict?
    }
    
    public struct TitleDict: Codable {
        public let title: [TitleItem]
    }
    public struct TitleItem: Codable {
        public let plain_text: String?
    }
}


final class SendTitle {                     ///so page title can be sent to supabase alongside page content in ImportUserPage.swift
    static let shareTitle = SendTitle(displayTitle: "")
    private init(displayTitle: String) {
        self.displayTitle = displayTitle
    }
    var displayTitle: String
}

final class LastEdited: ObservableObject {
    @Published var lastEditedAt: Date?
    static let shared = LastEdited()
}


@Model final class NotionPageMetaData {                 ///Notion page metadata schema for on-demand syncing/retrieval feature
    @Attribute(.unique) public var pageID: String
    
    var pageTitle: String
    var lastEditedAt: Date
    var lastFetchedAt: Date
    var isAutoSync: Bool
    var plain_text: String
    
    init(pageID: String, pageTitle: String, lastEditedAt: Date, lastFetchedAt: Date, isAutoSync: Bool, plain_text: String) {
        self.pageID = pageID
        self.pageTitle = pageTitle
        self.lastEditedAt = lastEditedAt
        self.lastFetchedAt = lastFetchedAt
        self.isAutoSync = isAutoSync
        self.plain_text = plain_text
    }
}


@MainActor
public class searchPages: ObservableObject {
    
    public static let shared = searchPages()
    
    @Published var emojis: NotionSearchRequest.Icon?
    @Published var displaying: NotionSearchRequest.TitleItem?
    @Published var userBlocks: NotionSearchRequest.result?
    
    @Published var id: String?
    @Published var icon: String?
    @Published var plain_text: String?
    @Published var emoji: String?
    
    
    
    @MainActor
    public func fetchAuthToken(context: ModelContext) throws -> String {
        let fetchDescriptor = FetchDescriptor<AuthToken>()
        let fetchAuth = try context.fetch(fetchDescriptor)
        
        guard let token = fetchAuth.first?.accessToken, !token.isEmpty else {
            throw URLError(.unknown)
        }
        return token
    }
    
    func fetchSyncPg(pageID: String, context: ModelContext) throws -> NotionPageMetaData? {          ///query synced page
        
        let fetchSyncPg = FetchDescriptor<NotionPageMetaData>(predicate: #Predicate { $0.pageID == pageID })
        return try context.fetch(fetchSyncPg).first
    }
    
    
    func fetchPg(pageID: String, context: ModelContext) throws -> UserPageTitle? {                     ///query un-synced page
        
        let fetchPg = FetchDescriptor<UserPageTitle>(predicate: #Predicate { $0.titleID == pageID })
        return try context.fetch(fetchPg).first
    }
    
    let searchEndpoint = URL(string: "https://api.notion.com/v1/search")
    private init() {}
    
    private func getPageData(text: String?, customType: String?, optionalEmoji: String, pageID: String, accessObject: String?, context: ModelContext) throws {
        
        
        DispatchQueue.main.async {
            if let titles = text {
                
                self.displaying = NotionSearchRequest.TitleItem(plain_text: titles)
                print("being passed to main thread: \(titles)")
            } else {
                print("plain text is not being run on main")
            }
            
            self.emojis = NotionSearchRequest.Icon(type: customType ?? "", emoji: optionalEmoji)
            print("emoji has been stored🫡\(optionalEmoji)")
        }
        
        
        if let objectBlocks = accessObject, let displayTitle = text {
            print("page ID: \(pageID)")
            print("content: \(objectBlocks)")
            print("title of page: \(displayTitle)")
            print("emoji from title:\(optionalEmoji)")
            
            
            if SyncController.shared.isAutoSync {
                if let existingTab = try fetchSyncPg(pageID: pageID, context: context) {        ///synced path
                    
                    existingTab.pageTitle = displayTitle
                    existingTab.plain_text = objectBlocks
                    try context.save()
                    
                    let storeSyncTitle = UserPageTitle(titleID: pageID, icon: customType, plain_text: displayTitle, emoji: optionalEmoji)
                    context.insert(storeSyncTitle)
                    try context.save()
                    
                    SendTitle.shareTitle.displayTitle = displayTitle
                }
            } else {
                if try fetchPg(pageID: pageID, context: context) == nil {                   ///non-syned path
                    let storedTitle = UserPageTitle(titleID: pageID, icon: customType, plain_text: displayTitle, emoji: optionalEmoji)
                    context.insert(storedTitle)
                    try context.save()
                    
                    SendTitle.shareTitle.displayTitle = displayTitle
                }
            }
        } else {
            print("an object is not being stored")
        }
    }
    
    
    public func userEndpoint(context: ModelContext) async throws {
        
        //        if SyncController.shared.isAutoSync && SyncController.shared.didRunBootstrap {
        //            return print("skipped call to userEndpoint, auto sync is on ")
        //        }
        
        
        guard let url = searchEndpoint else { return }
        var request = URLRequest(url: url)
        
        let passToken = try fetchAuthToken(context: context)
        
        guard !passToken.isEmpty else {
            return print("headers could not be added ❗️")
        }
        
        request.addValue("Bearer \(passToken)", forHTTPHeaderField: "Authorization")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        
        do {
            request.httpMethod = "POST"
            
            let (userData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            if let dataString = String(data: userData, encoding: .utf8) {
                print("EVERYTHING BELOW HERE IS USER ENDPOINT RESPONSE: \(dataString)")
            } else {
                print("empty data string")
            }
            
            
            let decodePageData = JSONDecoder()
            decodePageData.dateDecodingStrategy = .custom { decoder in
                
                let c = try decoder.singleValueContainer()
                let dateString = try c.decode(String.self)
                
                let format = ISO8601DateFormatter()
                format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
                
                if let date = format.date(from: dateString) { return date }
                
                format.formatOptions = [.withInternetDateTime]
                if let dateTime = format.date(from: dateString) { return dateTime }
                
                throw DecodingError.typeMismatch(Date.self,
                                                 DecodingError.Context(codingPath: c.codingPath,
                                                                       debugDescription: "Date string does not match expected format"))
            }
            
            let decodedPageStrings = try decodePageData.decode(NotionSearchRequest.self, from: userData)
            
            for page in decodedPageStrings.results {
                guard let pageID = page.id else { continue }
                
                if try isPageDeleted(pageID, in: context) {
                    continue
                }
                
                let lastEdited = page.last_edited_time
                print("LAST EDITED AT: \(lastEdited ?? Date())")
                
                await MainActor.run {
                    LastEdited.shared.lastEditedAt = lastEdited  //change later
                }
                
                let getText = page.properties?.title
                let text = getText?.title.first?.plain_text
                let emojis = page.icon?.emoji
                let customType = page.icon?.type
                let optionalEmoji = emojis ?? ""
                let syncedPageID = pageID
                
                
                guard let notionLastEditedTime = lastEdited else { continue }
            
                if let existingPageSync = try fetchSyncPg(pageID: syncedPageID, context: context) {     ///sync path to update existing page
                    
                    if notionLastEditedTime > existingPageSync.lastFetchedAt {
                        print("LAST EDITED: \(existingPageSync.lastEditedAt)", "|", "LAST FETCHED: \(existingPageSync.lastFetchedAt)")
                        
                        try getPageData(text: text, customType: customType, optionalEmoji: optionalEmoji, pageID: pageID, accessObject: text, context: context)
                        
                    } else {
                        continue
                    }
                    existingPageSync.lastEditedAt = notionLastEditedTime
                    existingPageSync.lastFetchedAt = Date()
                    try context.save()
                    
                } else {
                    
                    let firstTimePageSync = NotionPageMetaData(pageID: pageID, pageTitle: text!, lastEditedAt: notionLastEditedTime, lastFetchedAt: .distantPast, isAutoSync: true, plain_text: text ?? "")     ///sync path for page being imported for the first time
                    context.insert(firstTimePageSync)
                    
                    if notionLastEditedTime <= firstTimePageSync.lastFetchedAt { continue }
                    
                    try getPageData(text: text, customType: customType, optionalEmoji: optionalEmoji, pageID: pageID, accessObject: text, context: context)
                    print("TEXT TILE FIRST: \(text ?? "EMPTY")")
                    
                    firstTimePageSync.lastEditedAt = notionLastEditedTime
                    firstTimePageSync.lastFetchedAt = Date()
                    try context.save()
                    
                }
            }
        } catch {
            print("bad response")
            if let decodeBlocksError = error as? DecodingError {
                print("error in decoding blocks\(decodeBlocksError)")
            }
        }
    }
}





