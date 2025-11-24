
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
        let paragraph: Paragraph?
        var ExtractedFields: [String] = []
        
        private enum CodingKeys: CodingKey {
            case id
            case paragraph
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



public struct PushToSupabase: Encodable {
    var token: String
    var page_data: String
    var page_id: String
    var page_title: String
}

let supabaseDBClient = SupabaseClient(supabaseURL: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co")!,
                                      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ")

let authToken = accessToken ?? ""
var appendToken = "Bearer " + authToken

@MainActor
class ImportUserPage: ObservableObject {
    
    public static let shared = ImportUserPage()
    @Published var mainBlockBody: [MainBlockBody.Block] = []
    var appendedID: String?
    
    var modelContextPage: ModelContext?
    public func modelContextPagesStored(pagesContext: ModelContext?) {
        self.modelContextPage = pagesContext
    }
    var storeStrings: String?
    var userContentPage: String?
    var userPageId: String?
    var storePageIDSets: Set<String> = []
  
    public func pageEndpoint() async throws {
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
        
        guard !appendToken.isEmpty else { return }
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.addValue(appendToken, forHTTPHeaderField: "Authorization")
        print("page ID was successfully appended to the url")
       
        
        do {
            request.httpMethod = "GET"
            
            let (userData, response) = try await URLSession.shared.data(for: request)
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
                    buildNewURL.addValue(appendToken, forHTTPHeaderField: "Authorization")
                    
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
                if let paragraph = returnDecodedResults[i].paragraph, let richText = paragraph.rich_text {
                    for text in richText {
                        if let content = text.text?.content {
                            extractedFields.append(content)
                        }
                    }
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
                        print("page ids interted: \([storePageIDSets])")
                        pageID = returnedBlocks.first?.id ?? ""
                        
                        let remove = CharacterSet(charactersIn: "•")
                        let formatString = remove.union(.whitespacesAndNewlines)
                        let formattedString = storeStrings.trimmingCharacters(in: formatString)
                        
                        let storedPages = UserPageContent(userContentPage: formattedString, userPageId: pageID)
                        modelContextPage?.insert(storedPages)
                        print("SEND THIS TO SUPABASE: \(storeStrings)")
                        print("page id persited: \(pageID)")
                        
                        
                        Task {
                            for await data in Activity<DynamicRepAttributes>.pushToStartTokenUpdates {
                                let formattedTokenString = data.map {String(format: "%02x", $0)}.joined()
                                Logger().log("new push token created: \(data)")
                                
                                let pushAndPageData = PushToSupabase(token: formattedTokenString, page_data: formattedString, page_id: pageID, page_title: SendTitle.shareTitle.displayTitle)
                                let sendToken = try await supabaseDBClient.from("push_tokens").insert([pushAndPageData]).select("token, page_data, page_title").execute()
                                let sendID = try await supabaseDBClient.from("push_tokens").upsert([pushAndPageData]).select("page_id").execute()
                              
                                Logger().log("page_id successfully sent up to Supabase: \(String(describing:(sendID)))")
                                Logger().log("push token successfully sent up to Supabase: \(String(describing:(sendToken)))")
                               
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


