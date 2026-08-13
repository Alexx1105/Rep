//
//  SupabaseDataSourceStructs.swift
//  Rep
//
//  Created by alex haidar on 8/11/26.
/* Moved all Supabase data source struct definitions
   into here for mapping into supabase db table */
import Foundation


public struct PushToSupabaseNotion: Encodable {
    let token: String
    let page_data: String
    let page_id: String
    let page_title: String
    let content_hash: String
}


public struct PushToSupabaseOpenAi: Encodable {
    let token: String
    let openaiID: String
    let title: String
    let content: String
    let contentHash: String
    
    enum CodingKeys: String, CodingKey {
        case token = "token"
        case openaiID = "page_id"
        case content = "page_data"
        case title = "page_title"
        case contentHash = "content_hash"
    }
}

public struct PushToSupabaseRepDesktopNotes: Encodable {
    let token: String
    let userId: String
    let title: String
    let fullNotes: String
    let contentHash: String
    
    enum CodingKeys: String, CodingKey {
        case token = "token"
        case userId = "user_id"
        case title = "page_title"
        case fullNotes = "page_data"
        case contentHash = "content_hash"
    }
}
