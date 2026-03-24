//
//  NotionDataStructs.swift
//  Rep
//
//  Created by alex haidar on 3/21/26.
//Hold all notion data structs and future supported notion content types here
//(future claude, openAI support structs should be in a different file)
//TODO: change redeclared structs back to upper case when done
import Foundation



public struct NotionSearchRequest: Codable {        ///struct for getting first pass headers
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

public struct MainBlockBody: Codable, Identifiable {       ///follow-up struct for importing selected page
    public let id = UUID()
    let results: [Block]
    public let next_cursor: String?
    public let has_more: Bool
    
    private enum CodingKeys: CodingKey {
        case results
        case next_cursor
        case has_more
    }
    
    public struct Block: Codable {
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

public struct PushToSupabase: Encodable {
    var token: String
    var page_data: String
    var page_id: String
    var page_title: String
    var content_hash: String
}
