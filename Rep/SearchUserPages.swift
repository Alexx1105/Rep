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

public var returnedBlocks: [NotionSearchRequest.result] = []

final class SendTitle {    ///so page title can be sent to supabase alongside page content in ImportUserPage.swift
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
    
    
    var modelContextTitle: ModelContext?
    public func modelContextTitleStored(context: ModelContext?) {
        self.modelContextTitle = context
    }
    
    @MainActor
    public func fetchAuthToken(context: ModelContext) throws -> String {
        let fetchDescriptor = FetchDescriptor<AuthToken>()
        let fetchAuth = try context.fetch(fetchDescriptor)
        
        guard let token = fetchAuth.first?.accessToken, !token.isEmpty else {
            throw URLError(.unknown)
        }
        return token
    }
    
    func fetchSyncPg(pageID: String) throws -> NotionPageMetaData? {          ///query synced page
        guard let _ = modelContextTitle else { return nil }
        
        let fetchSyncPg = FetchDescriptor<NotionPageMetaData>(predicate: #Predicate { $0.pageID == pageID })
        return try modelContextTitle?.fetch(fetchSyncPg).first
    }
    
    func fetchPg(pageID: String) throws -> UserPageTitle? {                     ///query un-synced page
        guard let _ = modelContextTitle else { return nil }
        
        let fetchPg = FetchDescriptor<UserPageTitle>(predicate: #Predicate { $0.titleID == pageID })
        return try modelContextTitle?.fetch(fetchPg).first
    }
    
    let searchEndpoint = URL(string: "https://api.notion.com/v1/search")
    private init() {}
    
    private func getPageData(text: String?, customType: String?, optionalEmoji: String, returnedBlocks: [NotionSearchRequest.result], accessObject: String?) throws {
        
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
        
        if let pageID = returnedBlocks.first?.id, let objectBlocks = accessObject, let displayTitle = text {
            print("page ID: \(pageID)")
            print("content: \(objectBlocks)")
            print("title of page: \(displayTitle)")
            print("emoji from title:\(optionalEmoji)")
            
            
            if let existingTab = try fetchSyncPg(pageID: pageID) {
                
                existingTab.pageTitle = displayTitle
                try modelContextTitle?.save()
                SendTitle.shareTitle.displayTitle = displayTitle
                
            } else {
                
                let storedTitle = UserPageTitle(titleID: pageID, icon: customType, plain_text: displayTitle, emoji: optionalEmoji)
                modelContextTitle?.insert(storedTitle)
                try modelContextTitle?.save()
                
                SendTitle.shareTitle.displayTitle = displayTitle
            }
        } else {
            print("an object is not being stored")
        }
    }
    
    public func userEndpoint(modelContextTitle: ModelContext?, modelContext: ModelContext) async throws {
        guard let url = searchEndpoint else { return }
        var request = URLRequest(url: url)
        
        let passToken = try fetchAuthToken(context: modelContext)

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
            decodePageData.dateDecodingStrategy = .iso8601
            
            let decodedPageStrings = try decodePageData.decode(NotionSearchRequest.self, from: userData)
            returnedBlocks = decodedPageStrings.results
            let accessObject = returnedBlocks.first?.object
            
            let lastEdited = returnedBlocks.first?.last_edited_time
            print("LAST EDITED AT: \(lastEdited ?? Date())")
            
            await MainActor.run {
                LastEdited.shared.lastEditedAt = lastEdited
            }
            
            let title = decodedPageStrings.results.first
            let getText = title?.properties?.title
            let text = getText?.title.first?.plain_text
            let emojis = title?.icon?.emoji
            let customType = title?.icon?.type
            let optionalEmoji = emojis ?? ""
            let id = title?.id
            print("ID: \(id ?? "")")
    
            guard let syncedPageID = id, let notionLastEditedTime = lastEdited else { return }
            if let existingPageSync = try fetchSyncPg(pageID: syncedPageID) {
                
                if notionLastEditedTime > existingPageSync.lastFetchedAt {
                    print("LAST EDITED: \(existingPageSync.lastEditedAt)", "|", "LAST FETCHED: \(existingPageSync.lastFetchedAt)")
                    
                    try getPageData(text: text, customType: customType, optionalEmoji: optionalEmoji, returnedBlocks: returnedBlocks, accessObject: accessObject)
                    
                } else {
                    return
                }
                existingPageSync.lastEditedAt = notionLastEditedTime
                existingPageSync.lastFetchedAt = Date()
                try modelContextTitle?.save()
                
            } else {
                let firstTimePageSync = NotionPageMetaData(pageID: syncedPageID, pageTitle: text!, lastEditedAt: notionLastEditedTime, lastFetchedAt: .distantPast, isAutoSync: true, plain_text: accessObject ?? "plain text nil")
                modelContextTitle?.insert(firstTimePageSync)
                
                if notionLastEditedTime <= firstTimePageSync.lastFetchedAt { return }
            
                try getPageData(text: text, customType: customType, optionalEmoji: optionalEmoji, returnedBlocks: returnedBlocks, accessObject: accessObject)
                print("TEXT TILE FIRST: \(text ?? "EMPTY")")
                
                firstTimePageSync.lastEditedAt = notionLastEditedTime
                firstTimePageSync.lastFetchedAt = Date()
                try modelContextTitle?.save()
                
            }
        } catch {
            print("bad response")
            if let decodeBlocksError = error as? DecodingError {
                print("error in decoding blocks\(decodeBlocksError)")
            }
        }
    }
}





