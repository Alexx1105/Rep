//
//  McpClient.swift
//  Rep
//
//  Created by alex haidar on 11/26/26.
/* Handle supabase realtime subscription
   and recieving notes from rep mcp client */
import Foundation
import Supabase



class McpClientManager {
    func supabaseRealtimeListener() async throws {
        let session: Session = try await supabaseDBClient.auth.session
        let userID: String = session.user.id.uuidString.lowercased()
        let realtimeChannel: RealtimeChannelV2 = supabaseDBClient.channel("user:\(userID)") { config in
            config.isPrivate = true
        }
        let broadcast = realtimeChannel.broadcastStream(event: "rep-gpt-notes")
        
        try await realtimeChannel.subscribeWithError()
        try await decodeServerPayload(broadcast: broadcast)
    }
    
    
    func decodeServerPayload(broadcast: AsyncStream<[String: AnyJSON]>) async throws {
        for await notes in broadcast {
            guard let payload: AnyJSON = notes["payload"] else { continue }
            
            do {
                let encoder = try JSONEncoder().encode(payload)
                let decoder = JSONDecoder()
            
                let decodeNotes = try decoder.decode(RepGptNotesPayload.self, from: encoder)
                let mcpNotesTitle: String = decodeNotes.title ?? ""
                let mcpNotesContent: String = decodeNotes.content
                print("NOTES TITLE: \(mcpNotesTitle) | NOTES CONTENT: \(mcpNotesContent)")
                
            } catch {
                print("print failed to decode", ErrorDesc.decodeError, error)
            }
        }
    }
}

