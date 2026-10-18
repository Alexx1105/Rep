//
//  googleDocsStructs.swift
//  Rep
//
//  Created by alex haidar on 10/11/26.
import Foundation


public struct GoogleDocsSearchMetaData: Codable {        ///struct for getting first pass headers
    public let files: [Result]
    public let nextPageToken: String?
    public let incompleteSearch: Bool?
    
    public struct Result: Codable {
        public let id: String
        public let name: String
        public let modifiedTime: Date?
        public let webViewLink: String?
    }
}

public struct GoogleDocsPageResponse: Codable {          ///follow-up struct for importing selected document
    public let documentId: String
    public let title: String
    public let body: Body?
    public let tabs: [Tab]?
    
    public struct Tab: Codable {
        public let documentTab: DocumentTab?
        public let childTabs: [Tab]?
    }
    
    public struct DocumentTab: Codable {
        public let body: Body?
    }
    
    public struct Body: Codable {
        public let content: [Block]?
    }
    
    public struct Block: Codable {
        public let paragraph: Paragraph?
        public let table: Table?
        public let tableOfContents: Body?
    }
    
    public struct Paragraph: Codable {
        public let elements: [ParagraphElement]?
    }
    
    public struct ParagraphElement: Codable {
        public let textRun: TextRun?
    }
    
    public struct TextRun: Codable {
        public let content: String?
    }
    
    public struct Table: Codable {
        public let tableRows: [TableRow]?
    }
    
    public struct TableRow: Codable {
        public let tableCells: [Body]?
    }
}
