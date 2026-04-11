//
//  NotionDataManager.swift
//  Rep
//
//  Created by alex haidar on 3/16/26.
//
import Foundation
import SwiftData
import AuthenticationServices
import KimchiKit
import ActivityKit
import CryptoKit


@MainActor
public final class NotionDataManager: ObservableObject {
    public static let shared: NotionDataManager = NotionDataManager()
    private init() {}
    
    public func handlePageImported(context: ModelContext) {      ///main runner function
        Task {
            let importedPageTitles = try await fetchImportedPageTitles(context: context)
            for queriedPageIds in importedPageTitles {
                let fetchPageIDs: [String] = await PageDeletionManager.checkExistingPageIDs(pageID: queriedPageIds.pageID)
                let exisitng: Bool = fetchPageIDs.contains(queriedPageIds.pageID)
                print("does page id exist in db?: \(exisitng ? "yes" : "no")")
                
                guard !exisitng else { continue }
                
                for importedPageTitle in importedPageTitles {
                    let blocks = try await getBlocks(pageID: importedPageTitle.pageID, context: context)
                    extractFieldsFromBlocks(blocks, forUserPageTitle: importedPageTitle)
                }
            }
        }
    }
    
    private func fetchImportedPageTitles(context: ModelContext) async throws -> [UserPageTitle] {
        
        let fetch = FetchDescriptor<NotionPageMetaData>()
        let page = try context.fetch(fetch)
        
        let nonDeletedPages = try page.filter { pg in
            let deleted = try CheckDeletion.isPageDeleted(pg.pageID, in: context)
            print("deleted result:", deleted)
            
            return !deleted
        }
        var pageIDsImported: [UserPageTitle] = []
        for unDeletedPage in nonDeletedPages {          ///iterate over non-deleted pageIDs only, prevents ressurrection when sync is enabled
            
            let passToken = try FetchAuth.fetchAuthToken()
            guard !passToken.isEmpty else { throw ErrorDesc.authTokenError }
            
            let searchEndpoint: URL = URL(string: "https://api.notion.com/v1/search")!
            var urlRequest = URLRequest(url: searchEndpoint)
            urlRequest.addValue("Bearer \(passToken)", forHTTPHeaderField: "Authorization")
            urlRequest.addValue("2026-03-11", forHTTPHeaderField: "Notion-Version")
            urlRequest.httpMethod = "POST"
            
            do {
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
                
                guard let encodeData = String(data: data, encoding: .utf8) else { throw ErrorDesc.encodeError }
                print("encoded data: \(encodeData)")
                
                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .custom { decoder in
                    let c = try decoder.singleValueContainer()
                    let dateString = try c.decode(String.self)
                    
                    let format = ISO8601DateFormatter()
                    format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
                    
                    if let date = format.date(from: dateString) { return date }
                    
                    format.formatOptions = [.withInternetDateTime]
                    if let dateTime = format.date(from: dateString) { return dateTime }
                    
                    throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: c.codingPath,
                                                                                      debugDescription: "Date string does not match expected format"))
                }
                
                let searchResponse = try jsonDecoder.decode(NotionSearchResponse.self, from: data)
                for i in searchResponse.results {
                    guard !i.id.isEmpty else { continue }
                    
                    print("====================================\n Search Imported Page IDs result: \(i)")
                    let titleDictionary: NotionSearchResponse.TitleDict? = i.properties?.title
                    let emoji: String? = i.icon?.emoji
                    let lastEditedAt: Date? = i.last_edited_time
                    
                    let context = OAuthTokens.shared.modelContext
                    if let titleText: String = titleDictionary?.title.first?.plain_text {
                        print("====================================\n PLAIN TEXT TITLE ✅: \(titleText)")
                        
                        let fetch = FetchDescriptor<UserPageTitle>(predicate: #Predicate{ $0.pageID == i.id })
                        let fetchExistingPageTitle = try context?.fetch(fetch)
                        
                        if let existingTab = fetchExistingPageTitle?.first {                                       ///upsert tab
                            existingTab.text = titleText
                            existingTab.emoji = emoji
                        } else {
                            let firstTimeTab = UserPageTitle(pageID: i.id, text: titleText, emoji: emoji)          ///insert tab
                            pageIDsImported.append(firstTimeTab)
                        }
                        
                        if let existingMeta = try? FetchSynced.fetchSyncPg(pageID: i.id, context: context!) {     ///update existing sync
                            existingMeta.pageTitle = titleText
                            existingMeta.lastEditedAt = lastEditedAt ?? Date()
                            existingMeta.plain_text = titleText
                            existingMeta.isAutoSync = true
                        } else {
                            let newMeta = NotionPageMetaData(pageID: i.id, pageTitle: titleText, lastEditedAt: lastEditedAt ?? Date(), isAutoSync: true, plain_text: titleText)             ///insert first time sync
                            context?.insert(newMeta)
                        }
                    }
                }
                return pageIDsImported
                
            } catch {
                print("parsing error ❗️:", ErrorDesc.parsingError, error)
                return []
            }
        }
        return pageIDsImported
    }
    
    
    private func getBlocks(pageID: String, context: ModelContext) async throws -> [PageChildrenResponse.Block] {
        
        let desc = FetchDescriptor<NotionPageMetaData>()
        let pageId = try context.fetch(desc)
        
        for pg in pageId {
            let deleted = try CheckDeletion.isPageDeleted(pg.pageID, in: context)
            if deleted {
                print("deleted")
                continue
            }
        }
        
        let pagesEndpoint: String = "https://api.notion.com/v1/blocks/\(pageID)/children"
        guard let stringToUrl: URL = URL(string: pagesEndpoint) else { return [] }
        var request: URLRequest = URLRequest(url: stringToUrl)
        
        let auth = try FetchAuth.fetchAuthToken()
        guard !auth.isEmpty else { throw ErrorDesc.authTokenError }
        
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.addValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ErrorDesc.urlRequestError }
            
            let decoder = JSONDecoder()
            let pageChildrenResponse: PageChildrenResponse = try decoder.decode(PageChildrenResponse.self, from: data)
            
            var blocks: [PageChildrenResponse.Block] = pageChildrenResponse.results
            var hasMore: Bool = pageChildrenResponse.has_more
            var nextCursor: String? = pageChildrenResponse.next_cursor
            
            while hasMore, let cursor = nextCursor {
                let paginate: String = pagesEndpoint + "?page_size=100&start_cursor=\(cursor)"
                guard let paginateStringToUrl: URL = URL(string: paginate) else { throw ErrorDesc.paginationError }
                
                var paginationRequest: URLRequest = URLRequest(url: paginateStringToUrl)
                paginationRequest.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
                paginationRequest.addValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
                paginationRequest.httpMethod = "GET"
                
                let (paginatedData, _) = try await URLSession.shared.data(for: paginationRequest)
                let paginatedChildrenResponse = try JSONDecoder().decode(PageChildrenResponse.self, from: paginatedData)
                
                blocks.append(contentsOf: paginatedChildrenResponse.results)
                hasMore = paginatedChildrenResponse.has_more
                nextCursor = paginatedChildrenResponse.next_cursor
                print("paginated successfully ✅\n====================================")
            }
            
            return blocks
        } catch {
            print("error returning page blocks ❗️", ErrorDesc.parsingError, error)
            return []
        }
    }
    
    private func extractFieldsFromBlocks(_ blocks: [PageChildrenResponse.Block], forUserPageTitle userPageTitle: UserPageTitle) {
        var blocks = blocks
        
        for i in 0..<blocks.count {
            var extractedFields: [String] = []
            
            let blockList: PageChildrenResponse.Block = blocks[i]
            
            switch blockList.type {
            case "numbered_list_item":
                if let n = blockList.numbered_list_item?.rich_text {
                    extractedFields.append(n.map{ $0.text?.content ?? "" }.joined())
                }
            case "bulleted_list_item":
                if let b = blockList.bulleted_list_item?.rich_text {
                    extractedFields.append(b.map{ $0.text?.content ?? "" }.joined())
                }
            case "heading_1":
                if let h1 = blockList.heading_1?.rich_text {
                    extractedFields.append(h1.map{ $0.text?.content ?? "" }.joined())
                }
            case "heading_2":
                if let h2 = blockList.heading_2?.rich_text {
                    extractedFields.append(h2.map{ $0.text?.content ?? "" }.joined())
                }
            case "heading_3":
                if let h3 = blockList.heading_3?.rich_text {
                    extractedFields.append(h3.map{ $0.text?.content ?? "" }.joined())
                }
            default: break
            }
            
            if let paragraph = blockList.paragraph?.rich_text {
                let joinedContent: String = paragraph.map{ $0.text?.content ?? "" }.joined()
                extractedFields.append(contentsOf: [joinedContent])
                print("ALL LISTS ✅: \(joinedContent)")
            }
            
            blocks[i].extractedFields = extractedFields
        }
        
        let formattedString: String = blocks.flatMap{ $0.extractedFields }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let chunkedRows: [String] = formattedString.components(separatedBy: "\n• ").flatMap {$0.components(separatedBy: "\n")}
        print("formatted & trimmed string ✅: \(chunkedRows)")
        
        Task {
            do {
                let context = OAuthTokens.shared.modelContext
                let pageID: String = userPageTitle.pageID
                let fetch = FetchDescriptor<UserPageContent>(predicate: #Predicate { $0.userPageId == pageID })
                
                if let contentExists = try context?.fetch(fetch).first {                                         ///existing saved tab (synced)
                    contentExists.userContentPage = formattedString
                } else {
                    let content = UserPageContent(userContentPage: formattedString, userPageId: userPageTitle.pageID)     ///first time import
                    let title = UserPageTitle(pageID: pageID, text: userPageTitle.text, emoji: userPageTitle.emoji)
                    context?.insert(content)
                    context?.insert(title)
                    try context?.save()
                }
            } catch {
                print("Error persisting to CoreData ❗️", ErrorDesc.persistenceError, error)
            }
            
            let token: String = await PushTokenManager.generatePushToken()
            guard !chunkedRows.isEmpty || !token.isEmpty else { throw ErrorDesc.nilValue }
            
            await withTaskGroup(of: Void.self) {
                $0.addTask {
                    for row in chunkedRows {
                        let contentHash: String = SHA256.hash(data: row.data(using: .utf8)!).map{String(format: "%02x", $0)}.joined()
                        await SupabaseClientManager.shared.supabaseUpsert(token: token, pageID: userPageTitle.pageID, row: row, pageTitle: userPageTitle.text, content_hash: contentHash)
                        print("==========================\nsplit rows for supaabse upsert ✅: \(row) \nhash: \(contentHash)")
                    }
                }
            }
        }
    }
}
