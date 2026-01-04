//
//  ImportUserPages.swift
//  MuscleMemory
//
//  Created by alex haidar on 12/8/24.
//

import Foundation
import SwiftData

public struct NotionSearchRequest: Codable {    
    public let results: [result]
    public let object: String?
  
    
    public struct result: Codable {
        public let id: String?
        public let object: String?
        public let properties: properties?
        public let icon: Icon?
     
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
   
    let searchEndpoint = URL(string: "https://api.notion.com/v1/search")
    private init() {}
    
    
    
    public func userEndpoint(modelContextTitle: ModelContext?) async throws {
        guard let url = searchEndpoint else { return }
        var request = URLRequest(url: url)
        
        if let passToken = accessToken {
            request.addValue("Bearer \(passToken)", forHTTPHeaderField: "Authorization")
            request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
            
        } else {
            print("header values could not be added")
        }
    
        do {
            request.httpMethod = "POST"
            
            let (userData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            print("EVERYTHIGN BELOW IS USER ENDPOINT RESPONSE: \n")
            if let dataString = String(data: userData, encoding: .utf8) {
                print(dataString)
            } else {
                print("empty data string")
            }
            
            let decodePageData = JSONDecoder()
            let decodedPageStrings = try decodePageData.decode(NotionSearchRequest.self, from: userData)
            returnedBlocks = decodedPageStrings.results
            let accessObject = returnedBlocks.first?.object
           
            let title = decodedPageStrings.results.first
            let getText = title?.properties?.title
            let text = getText?.title.first?.plain_text
            let emojis = title?.icon?.emoji
            let customType = title?.icon?.type
            
            let optionalEmoji = emojis ?? ""
           
            DispatchQueue.main.async {
                
                if let titles = text {
                   
                    self.displaying = NotionSearchRequest.TitleItem(plain_text: titles)
                        print("being passed to main thread: \(titles)")
                    } else {
                        print("plain text is not being run on main")
                    }
                
                self.emojis = NotionSearchRequest.Icon(type: customType ?? "", emoji: optionalEmoji)
                self.emojis = NotionSearchRequest.Icon(type: customType, emoji: optionalEmoji)
                print("emoji has been stored🫡\(optionalEmoji)")
            }
            
            if let pageID = returnedBlocks.first?.id, let objectBlocks = accessObject, let displayTitle = text {
                print("page ID: \(pageID)")
                print("content: \(objectBlocks)")
                print("title of page: \(displayTitle)")
                print("emoji from title:\(optionalEmoji)")
                
                let storedTitle = UserPageTitle(titleID: pageID, icon: customType, plain_text: displayTitle, emoji: optionalEmoji)
                modelContextTitle?.insert(storedTitle)
                try modelContextTitle?.save()

                SendTitle.shareTitle.displayTitle = displayTitle
                
            } else {
                print("an object is not being stored")
            }
            
        } catch {
            print("bad response")
            if let decodeBlocksError = error as? DecodingError {
                print("error in decoding blocks\(decodeBlocksError)")
            }
        }
    }
}




