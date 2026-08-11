//
//  AudioTranscriptionDesktopPoller.swift
//  Rep
//
//  Created by alex haidar on 7/18/26.
//
/* A task management and and notes polling class that pulls transcripted
   notes + transcript from the rep desktop helper app and adds them to
   the mobile app for use with the LiveActivity flashcards + caches locally
   and upserts to the supabase db */
import Foundation
import Supabase
import SwiftUI
import SwiftData


@MainActor
final class RepDesktopPoller: ObservableObject {
    private init() {}

    static let shared = RepDesktopPoller()
    private var task: Task<Void, Never>?
    
    func startPollingNotes(context: ModelContext) {
        task?.cancel()
        
        task = Task {
            while !Task.isCancelled {
                do {
                    try await getQueuedDesktopNotes(context: context)
                    try? await Task.sleep(for: .seconds(10))
                } catch {
                    print("failed to start polling", ErrorDesc.taskError, error)
                    try? await Task.sleep(for: .seconds(10))
                }
            }
        }
        print("started polling...")
    }
    
    
    func stopPollingNotes() {
        task?.cancel()
        task = nil
        print("polling stopped")
    }
    
    
    func getQueuedDesktopNotes(context: ModelContext) async throws {
        
        let session: Session = try await supabaseDBClient.auth.session
        guard !session.isExpired else { throw ErrorDesc.authTokenError }
        
        var request: URLRequest = URLRequest(url: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat-dev")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("desktop_notes", forHTTPHeaderField: "x-rep-action")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else { throw ErrorDesc.urlResponseError }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(DesktopNotes.self, from: data)
        
        guard let firstNote = result.notes.first else { return }
        
        let fullTranscript: String = firstNote.transcript ?? "no transcript"
        let fullNotes: String = firstNote.notes ?? "no notes"
        let userId: String = firstNote.id
        let createdAt: String = firstNote.created_at
        let title =  String(fullNotes.prefix(30))
        
        print("FULL TRANSCRIPT: \(fullTranscript)")
        print("FULL NOTES: \(fullNotes)")
        print("user id: \(userId) | created at: \(createdAt)")
        print("title: \(title)")
        
        let repDesktopTranscription: RepDesktopTranscription = RepDesktopTranscription(userId: userId, fullTranscript: fullTranscript, fullNotes: fullNotes, createdAt: createdAt)
        context.insert(repDesktopTranscription)
        try context.save()
        
        if !fullNotes.isEmpty && !userId.isEmpty {
            try await SupabaseClientManager.shared.upsertRepDesktopNotes(fullNotes: fullNotes, userId: userId, title: title)
        }
    }
}


