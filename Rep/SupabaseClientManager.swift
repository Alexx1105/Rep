//
//  SupabaseServer.swift
//  Rep
//
//  Created by alex haidar on 3/28/26.
///Supabase db client lives here now, all future supabase ops from the client should be managed here

import Foundation
import Supabase


let supabaseDBClient = SupabaseClient(supabaseURL: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co")!,
                                      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ")

public struct PushToSupabase: Encodable {
    var token: String
    var page_data: String
    var page_id: String
    var page_title: String
    var content_hash: String
}

public enum SupabaseError: LocalizedError {
    case upsertError
    case nilDataError
}

@MainActor
public final class SupabaseClientManager: ObservableObject {
    public static let shared = SupabaseClientManager()
    
    public func supabaseUpsert(token: String, pageID: String, row: String, pageTitle: String, content_hash: String) async {
        
        do {
            guard !token.isEmpty || !row.isEmpty || !pageID.isEmpty else { throw SupabaseError.nilDataError }
            
            let schema = PushToSupabase(token: token, page_data: row, page_id: pageID, page_title: pageTitle, content_hash: content_hash)
            let send = try await supabaseDBClient.from("push_tokens").upsert([schema], onConflict: "page_id, content_hash").select("token, page_id, content_hash, page_data, page_title").execute()
            
            print("page data successfully inserted ✅:", send)
        } catch {
            print("supabse insertion errror ❗️", SupabaseError.upsertError, error)
        }
    }
}
