
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
    
    private enum CodingKeys: CodingKey {
        case results
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
}

let supabaseDBClient = SupabaseClient(supabaseURL: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co")!,
                                      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ")


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
    
    public func pageEndpoint() async throws {
        let pageID = returnedBlocks.first?.id ?? "pageID is nil"
        let pagesEndpoint = "https://api.notion.com/v1/blocks/"
        let append = pagesEndpoint + "\(pageID)/children"
        
        appendedID = append                             //assign before being compared so it is not nil by default
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
        
        if let authToken = accessToken {
            let appendToken = "Bearer " + authToken
            request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
            request.addValue(appendToken, forHTTPHeaderField: "Authorization")
            print("page ID was successfully appended to the url")
            print(appendToken)
        } else {
            print("headers could not be added or token could not be appended")
        }
        
        
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
            var returnDecodedResults = decodePage.results
            
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
                        
                        let pageID = returnedBlocks.first?.id ?? ""
                        let storedPages = UserPageContent(userContentPage: storeStrings, userPageId: pageID)
                        modelContextPage?.insert(storedPages)
                        print("SEND THIS TO SUPABASE: \(storeStrings)")
                        print("block id persited: \(pageID)")
                        
                        Task { [pageIDString = i.id] in
                            
                            for await data in Activity<DynamicRepAttributes>.pushToStartTokenUpdates {
                                let formattedTokenString = data.map {String(format: "%02x", $0)}.joined()
                                Logger().log("new push token created: \(data)")
                                
                                let pushAndPageData = PushToSupabase(token: formattedTokenString, page_data: storeStrings, page_id: pageIDString)
                                let sendToken = try await supabaseDBClient.from("push_tokens").insert([pushAndPageData]).select("token, page_data").execute()
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


