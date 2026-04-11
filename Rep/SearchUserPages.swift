//
//  ImportUserPages.swift
//  MuscleMemory
//
//  Created by alex haidar on 12/8/24.
//
//
//import Foundation
//import SwiftData
//import OSLog
//
//
//public struct NotionSearchRequest: Codable {
//    public let results: [result]
//    public let object: String?
//    
//    public struct result: Codable {
//        public let id: String?
//        public let object: String?
//        public let properties: properties?
//        public let icon: Icon?
//        public let last_edited_time: Date?
//        public let created_time: Date?
//    }
//    
//    public struct Icon: Codable {
//        public let type: String?
//        public let emoji: String?
//    }
//    
//    public struct properties: Codable {
//        public let title: TitleDict?
//    }
//    
//    public struct TitleDict: Codable {
//        public let title: [TitleItem]
//    }
//    public struct TitleItem: Codable {
//        public let plain_text: String?
//    }
//}
//
//
//final class SendTitle {                     ///so page title can be sent to supabase alongside page content in ImportUserPage.swift
//    static let shareTitle = SendTitle(displayTitle: "")
//    private init(displayTitle: String) {
//        self.displayTitle = displayTitle
//    }
//    var displayTitle: String
//}
//
//final class LastEdited: ObservableObject {
//    @Published var lastEditedAt: Date?
//    @Published var lastFetchedAt: Date?
//    static let shared = LastEdited()
//}
//
//
//@Model final class NotionPageMetaData {                 ///Notion page metadata schema for on-demand syncing/retrieval feature
//    @Attribute(.unique) public var pageID: String
//    
//    var pageTitle: String
//    var lastEditedAt: Date
//    var lastFetchedAt: Date
//    var isAutoSync: Bool
//    var plain_text: String
//    
//    
//    init(pageID: String, pageTitle: String, lastEditedAt: Date, lastFetchedAt: Date, isAutoSync: Bool, plain_text: String) {
//        self.pageID = pageID
//        self.pageTitle = pageTitle
//        self.lastEditedAt = lastEditedAt
//        self.lastFetchedAt = lastFetchedAt
//        self.isAutoSync = isAutoSync
//        self.plain_text = plain_text
//    }
//}
//
//
//@Model final class DeletedPage {
//    @Attribute(.unique) var pageID: String
//    var deletedAt: Date = Date()
//    init(pageID: String) { self.pageID = pageID }
//}
//
//@MainActor
//func isPageDeleted(_ pageID: String, in context: ModelContext) throws -> Bool {
//    let desc = FetchDescriptor<DeletedPage>(predicate: #Predicate { $0.pageID == pageID })
//    return try context.fetch(desc).first != nil
//    
//}
//
//
//@MainActor
//public class searchPages: ObservableObject {
//    
//    public static let shared = searchPages(id: "")
//    
//    @Published var emojis: NotionSearchRequest.Icon?
//    @Published var displaying: NotionSearchRequest.TitleItem?
//    @Published var userBlocks: NotionSearchRequest.result?
//    
//    @Published var id: String
//    @Published var icon: String?
//    @Published var plain_text: String?
//    @Published var emoji: String?
//    
//    
//    
//    @MainActor
//    public func fetchAuthToken(context: ModelContext) throws -> String {
//        let fetchDescriptor = FetchDescriptor<AuthToken>()
//        let fetchAuth = try context.fetch(fetchDescriptor)
//        
//        guard let token = fetchAuth.first?.accessToken, !token.isEmpty else {
//            throw URLError(.unknown)
//        }
//        return token
//    }
//    
//    let searchEndpoint = URL(string: "https://api.notion.com/v1/search")
//    private init(id: String) {
//        self.id = id
//    }
//    
//    private func getPageData(text: String?, customType: String?, optionalEmoji: String, pageID: String, accessObject: String?, context: ModelContext, existingTab: NotionPageMetaData) throws {
//        
//        if let titles = text {
//            
//            self.displaying = NotionSearchRequest.TitleItem(plain_text: titles)
//            print("being passed to main thread: \(titles)")
//        } else {
//            print("plain text is not being run on main")
//        }
//        
//        self.emojis = NotionSearchRequest.Icon(type: customType ?? "", emoji: optionalEmoji)
//        print("emoji has been stored🫡\(optionalEmoji)")
//        
//        
//        if let objectBlocks = accessObject, let displayTitle = text {
//            print("page ID: \(pageID)")
//            print("content: \(objectBlocks)")
//            print("title of page: \(displayTitle)")
//            print("emoji from title:\(optionalEmoji)")
//            
//            
//            let pageTitle = displayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
//            guard !pageTitle.isEmpty else { return }
//            
//            SendTitle.shareTitle.displayTitle = pageTitle
//            
//            if SyncController.shared.isAutoSync {
//                existingTab.pageTitle = pageTitle
//                existingTab.plain_text = objectBlocks
//            }
//            
//            if let existingTabSync = try fetchPg(pageID: pageID, context: context) {        ///upsert
//                existingTabSync.plain_text = pageTitle
//                existingTabSync.icon = customType
//                existingTabSync.emoji = optionalEmoji
//            } else {
//                let storedTitle = UserPageTitle(        ///insert
//                    titleID: pageID,
//                    icon: customType,
//                    plain_text: pageTitle,
//                    emoji: optionalEmoji
//                )
//                context.insert(storedTitle)
//            }
//        } else {
//            print("an object is not being stored")
//        }
//    }
//    
//    
//    public func userEndpoint(context: ModelContext) async throws {
//        
//        let fetch = FetchDescriptor<NotionPageMetaData>()
//        let page = try context.fetch(fetch)
//        
//        for pg in page {
//            let deleted = try isPageDeleted(pg.pageID, in: context)
//            print("deleted result:", deleted)
//            
//            if deleted {
//                print("skipped!")
//                continue
//            }
//        }
//        
//        guard let url = searchEndpoint else { return }
//        var request = URLRequest(url: url)
//        
//        let passToken = try fetchAuthToken(context: context)
//        
//        guard !passToken.isEmpty else {
//            return print("headers could not be added ❗️")
//        }
//        
//        request.addValue("Bearer \(passToken)", forHTTPHeaderField: "Authorization")
//        request.addValue("2026-03-11", forHTTPHeaderField: "Notion-Version")
//        
//        
//        do {
//            request.httpMethod = "POST"
//            
//            let (userData, response) = try await URLSession.shared.data(for: request)
//            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                throw URLError(.badServerResponse)
//            }
//            
//            
//            if let dataString = String(data: userData, encoding: .utf8) {
//                print("EVERYTHING BELOW HERE IS USER ENDPOINT RESPONSE: \(dataString)")
//            } else {
//                print("empty data string")
//            }
//            
//            let decodePageData = JSONDecoder()
//            decodePageData.dateDecodingStrategy = .custom { decoder in
//                
//                let c = try decoder.singleValueContainer()
//                let dateString = try c.decode(String.self)
//                
//                let format = ISO8601DateFormatter()
//                format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
//                
//                if let date = format.date(from: dateString) { return date }
//                
//                format.formatOptions = [.withInternetDateTime]
//                if let dateTime = format.date(from: dateString) { return dateTime }
//                
//                throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: c.codingPath,
//                                                                                  debugDescription: "Date string does not match expected format"))
//            }
//            
//            let decodedPageStrings = try decodePageData.decode(NotionSearchRequest.self, from: userData)
//            
//            for page in decodedPageStrings.results {
//                guard let pageID = page.id else { continue }
//  
//                if try isPageDeleted(pageID, in: context) {
//                    if let deleteMeta = try fetchSyncPg(pageID: pageID, context: context) {
//                        context.delete(deleteMeta)
//                    }
//                    
//                    if let deleteMeta = try fetchPg(pageID: pageID, context: context) {
//                        context.delete(deleteMeta)
//                    }
//                    print("deleted page data 🗑️")
//                    continue
//                }
//                
//                
//                let lastEdited = page.last_edited_time
//                print("LAST EDITED AT: \(lastEdited ?? Date())")
//                
//                await MainActor.run {
//                    LastEdited.shared.lastEditedAt = lastEdited  //change later
//                }
//                
//                let getText = page.properties?.title
//                let text: String? = getText?.title.first?.plain_text
//                let emojis: String? = page.icon?.emoji
//                let customType: String? = page.icon?.type
//                let optionalEmoji = emojis ?? ""
//                let syncedPageID = pageID
//                
//                
//                guard let notionLastEditedTime = lastEdited else { continue }
//                if let existingPageSync = try fetchSyncPg(pageID: syncedPageID, context: context) {     ///sync path to update existing page
//                    
//                    await MainActor.run {
//                        LastEdited.shared.lastFetchedAt = existingPageSync.lastFetchedAt
//                    }
//                    
//                    print("LAST EDITED: \(existingPageSync.lastEditedAt)", "|", "LAST FETCHED: \(existingPageSync.lastFetchedAt)")
//                    try getPageData(text: text, customType: customType, optionalEmoji: optionalEmoji, pageID: pageID, accessObject: text, context: context, existingTab: existingPageSync)
//                    
//                    existingPageSync.lastEditedAt = notionLastEditedTime
//                    existingPageSync.lastFetchedAt = Date()
//                    
//                } else {
//                    
//                    let firstTimePageSync = NotionPageMetaData(pageID: pageID, pageTitle: text ?? "", lastEditedAt: notionLastEditedTime, lastFetchedAt: .distantPast, isAutoSync: true, plain_text: text ?? "")     ///sync path for page being imported for the first time
//                    context.insert(firstTimePageSync)
//                    
//                    try getPageData(text: text, customType: customType, optionalEmoji: optionalEmoji, pageID: pageID, accessObject: text, context: context, existingTab: firstTimePageSync)
//                    print("TEXT TILE FIRST: \(text ?? "EMPTY")")
//                    
//                    firstTimePageSync.lastEditedAt = notionLastEditedTime
//                    firstTimePageSync.lastFetchedAt = Date()
//                    
//                }
//            }
//            try context.save()
//            
//        } catch {
//            print("bad response")
//            if let decodeBlocksError = error as? DecodingError {
//                print("error in decoding blocks\(decodeBlocksError)")
//            }
//        }
//    }
//}
//




