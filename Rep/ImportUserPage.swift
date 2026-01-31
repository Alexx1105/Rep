
//  ImportUserPage.swift
//  MuscleMemory
//
//  Created by alex haidar on 12/22/24.
//


import Foundation
import SwiftData
import Supabase
import OSLog
import ActivityKit
import KimchiKit
import CryptoKit



struct MainBlockBody: Codable, Identifiable {
    let id = UUID()
    let results: [Block]
    let next_cursor: String?
    let has_more: Bool
    
    private enum CodingKeys: CodingKey {
        case results
        case next_cursor
        case has_more
    }
    
    struct Block: Codable {
        let id: String
        let type: String
        let paragraph: Paragraph?
        let bulleted_list_item: Paragraph?
        let numbered_list_item: Paragraph?
        let heading_1: Paragraph?
        let heading_2: Paragraph?
        let heading_3: Paragraph?
       
        var ExtractedFields: [String] = []
        
        private enum CodingKeys: CodingKey {
            case id
            case type
            case paragraph
            case bulleted_list_item
            case numbered_list_item
            case heading_1
            case heading_2
            case heading_3
        }
    }
    
    struct Paragraph: Codable {
        let rich_text: [RichText]?
    }
    struct RichText: Codable {
        let text: NotionText?
    }
    struct NotionText: Codable {
        let content: String?
    }
}

extension MainBlockBody {
    static func joinContent(_ c: [MainBlockBody.RichText]) -> String {
        c.map{ $0.text?.content ?? "" }.joined()
    }
}


public struct PushToSupabase: Encodable {
    var token: String
    var page_data: String
    var page_id: String
    var page_title: String
    var content_hash: String
}


let supabaseDBClient = SupabaseClient(supabaseURL: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co")!,
                                      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ")


@Model final class SyncUserContentPage {
    @Attribute(.unique) var hashed: String
    
     var content: String
     var pageID: String
    
    init(hashed: String, content: String, pageID: String) {
        self.content = content
        self.pageID = pageID
        self.hashed = hashed
    }
}


@MainActor
class ImportUserPage: ObservableObject {
    
    public static let shared = ImportUserPage()
    @Published var mainBlockBody: [MainBlockBody.Block] = []
    var appendedID: String?
    
    var modelContextPage: ModelContext?
    public func modelContextPagesStored(pagesContext: ModelContext?) {
        self.modelContextPage = pagesContext
    }
    
    
    @MainActor
    public func fetchAuthToken(context: ModelContext) throws -> String {
        let descriptor = FetchDescriptor<AuthToken>()
        let fetch = try context.fetch(descriptor)
        
        guard let token = fetch.first?.accessToken, !token.isEmpty else {
            throw URLError(.unknown)
        }
        return token
    }
    
    var storeStrings: String?
    var userContentPage: String?
    var userPageId: String?
    var storePageIDSets: Set<String> = []
    
    func fetchSyncContent(hash: String) throws -> SyncUserContentPage? {
        guard let _ = modelContextPage else { return nil }
        
        let fetch = FetchDescriptor<SyncUserContentPage>(predicate: #Predicate { $0.hashed == hash })
        return try modelContextPage?.fetch(fetch).first
    }
    
    
    public func pageEndpoint(modelContext: ModelContext) async throws {
        let pageID = returnedBlocks.first?.id ?? "pageID is nil"
        let pagesEndpoint = "https://api.notion.com/v1/blocks/"
        let append = pagesEndpoint + "\(pageID)/children"
      
        appendedID = append
        if appendedID == append {
            print("page ID was appended")
        } else {
            print("page id could not be appended")
        }
        
        if let unwrappedPageID = appendedID {
            print("pageID was successfully unwrapped before being passed to URL method:\(unwrappedPageID)")
        }
        
        let addURL = URL(string: appendedID ?? "appendedID could not be converted back into a URL (nill)")
        
        guard let url = addURL else { return }
        var request = URLRequest(url: url)
        
        let passAuth = try fetchAuthToken(context: modelContext)
        print("token is: \(passAuth)")
        
        guard !passAuth.isEmpty else {
            return print("auth token is nil ❗️")
        }
        
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.addValue("Bearer \(passAuth)", forHTTPHeaderField: "Authorization")
        print("page ID was successfully appended to the url")
        
        
        do {
            request.httpMethod = "GET"
            
            let (userData, response) = try await URLSession.shared.data(for: request)
            print("RESP: \(response)")
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            if let decodeString = String(data: userData, encoding: .utf8) {
                print(decodeString)
            } else {
                print("error decoding string")
            }
            
            let decodePageData = JSONDecoder()
            let decodePage = try decodePageData.decode(MainBlockBody.self, from: userData)
        
            var allResults = decodePage.results
            var moreResults = decodePage.has_more
            var cursor = decodePage.next_cursor
         
            while moreResults, let _ = cursor {
                if let nextCursor = decodePage.next_cursor {
                    let paginate = append + "?page_size=100&start_cursor=\(nextCursor)"
                    let nextURL = URL(string: paginate)
                    
                    var buildNewURL = URLRequest(url: nextURL!)
                    buildNewURL.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
                    buildNewURL.addValue("Bearer \(passAuth)", forHTTPHeaderField: "Authorization")
                    
                    let (nextData, _) = try await URLSession.shared.data(for: buildNewURL)
                    let decodeNextPageData = try JSONDecoder().decode(MainBlockBody.self, from: nextData)
                    print("decoded paginated data: \(decodeNextPageData)")
                    
                    allResults.append(contentsOf: decodeNextPageData.results)
                    moreResults = decodeNextPageData.has_more
                    cursor = decodeNextPageData.next_cursor
                    
                    print("paginated successfully ✅")
                } else {
                    print("page pagination with next_cursor failed ❌")
                }
            }
            
            var returnDecodedResults = allResults
            
            for i in 0..<returnDecodedResults.count {
                var extractedFields: [String] = []
                let blockList = returnDecodedResults[i]
                
                switch blockList.type {
                case "numbered_list_item":
                    if let n = blockList.numbered_list_item?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(n))
                    }
                case "bulleted_list_item":
                    if let b = blockList.bulleted_list_item?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(b))
                    }
                case "heading_1":
                    if let h1 = blockList.heading_1?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(h1))
                    }
                case "heading_2":
                    if let h2 = blockList.heading_2?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(h2))
                    }
                case "heading_3":
                    if let h3 = blockList.heading_3?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(h3))
                    }
                default: break
                }
                
                if let paragraph = returnDecodedResults[i].paragraph?.rich_text {
    
                    let joinedContent = MainBlockBody.joinContent(paragraph)
                    extractedFields.append(contentsOf: [joinedContent])
                    print("ALL LISTS: \(joinedContent)")
                }
                returnDecodedResults[i].ExtractedFields = extractedFields
            }
            
            DispatchQueue.main.async {
                self.mainBlockBody = returnDecodedResults
            }
            
            
            do {
                for i in returnDecodedResults {
                    for storeStrings in i.ExtractedFields {
                        
                        var pageID = returnedBlocks.first?.id ?? ""
                        storePageIDSets.insert(pageID)
                        pageID = returnedBlocks.first?.id ?? ""
                        
                        let formattedString = storeStrings.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("bullet point text: \(formattedString)")
                        
                        
                        Task {
                            for await data in Activity<DynamicRepAttributes>.pushToStartTokenUpdates {
                                let formattedTokenString = data.map {String(format: "%02x", $0)}.joined()
                                Logger().log("new push token created: \(data)")
                                
                                let chunkedRows = formattedString.components(separatedBy: "\n• ").flatMap {$0.components(separatedBy: "\n")}
                                print("SEPARATED BY NEW LINE: \(chunkedRows)")
                                
                                for row in chunkedRows {
                                    print("did content change?: \(row)")
                                    
                                    let hashContent = SHA256.hash(data: row.data(using: .utf8)!).map{String(format: "%02x", $0)}.joined()
                                    
                                    if try fetchSyncContent(hash: hashContent) == nil {   ///hash does not exist = content changed
                                        let storeSyncedPages = SyncUserContentPage(hashed: hashContent, content: row, pageID: pageID)
                                        modelContextPage?.insert(storeSyncedPages)
                                        
                                        print("did hash change?: \(hashContent)")
                                        
                                    } else {
                                        continue
                                    }
                                             
                                    do {
                                        let pushAndPageData = PushToSupabase(token: formattedTokenString, page_data: row, page_id: pageID, page_title: SendTitle.shareTitle.displayTitle, content_hash: hashContent)
                                        print("compare page data before supabase send: \(row)")
                                        //let sendToken = try await supabaseDBClient.from("push_tokens").insert([pushAndPageData]).select("token, page_data, page_title").execute()
                                        let sendID = try await supabaseDBClient.from("push_tokens").upsert([pushAndPageData], onConflict: "page_id, content_hash").select("token, page_id, content_hash, page_data, page_title").execute()
                                        
                                        Logger().log("page_id successfully sent up to Supabase: \(String(describing:(sendID)))")
                                        //Logger().log("push token successfully sent up to Supabase: \(String(describing:(sendToken)))")
                                   
                                    } catch {
                                        print("supabse insertion errror ❗️\(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    }
                }
                try modelContextPage?.save()
                
            } catch {
                print("url session error:\(error)")
                if let decodeBlocksError = error as? DecodingError {
                    print("error in decoding blocks\(decodeBlocksError.localizedDescription)")
                }
            }
        } catch {
            print("page data did not send to supabase: \(error.localizedDescription)")
        }
    }
}


