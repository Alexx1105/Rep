//
//  SupabaseServer.swift
//  Rep
//
//  Created by alex haidar on 3/28/26.


import Foundation
import Supabase
import CryptoKit


let supabaseDBClient: SupabaseClient = SupabaseClient(supabaseURL: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co")!,
                                                      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ")

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


@MainActor
public final class SupabaseClientManager: ObservableObject {
    public static let shared = SupabaseClientManager()
    
    public func supabaseNotionUpsert(token: String, pageID: String, row: String, pageTitle: String, content_hash: String) async {
        
        do {
            guard !token.isEmpty && !row.isEmpty && !pageID.isEmpty else { throw SupabaseError.nilDataError }
            
            let schema: PushToSupabaseNotion = PushToSupabaseNotion(token: token, page_data: row, page_id: pageID, page_title: pageTitle, content_hash: content_hash)
            let send = try await supabaseDBClient.from("push_tokens").upsert([schema], onConflict: "page_id, content_hash").select("token, page_id, content_hash, page_data, page_title").execute()
            
            print("[notion page] page data successfully inserted ✅:", send)
        } catch {
            print("supabse insertion errror ❗️", SupabaseError.upsertError, error)
        }
    }
    
    
    public func supabaseOpenaiChatUpsert(openaiID: String, title: String, content: String, token: String) async {
        
        let hash: Data = Data(content.utf8)
        let hashed = SHA256.hash(data: hash).map { String(format: "%02x", $0) }.joined()
        print("generated local hash:", hashed)
        
        do {
            guard !openaiID.isEmpty && !title.isEmpty && !content.isEmpty && !token.isEmpty else { throw SupabaseError.nilDataError }
            
            let schema: PushToSupabaseOpenAi = PushToSupabaseOpenAi(token: token, openaiID: openaiID, title: title, content: content, contentHash: hashed)
            let send = try await supabaseDBClient.from("push_tokens").upsert([schema], onConflict: "page_id, content_hash").select("token, page_id, page_data, page_title").execute()
            
            print("==========\npage data successfully inserted ✅:", send)
        } catch {
            print("[openai chat] supabse insertion errror ❗️", SupabaseError.upsertError, error)
        }
    }
}
