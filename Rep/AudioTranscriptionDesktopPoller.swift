//
//  AudioTranscriptionDesktopPoller.swift
//  Rep
//
//  Created by alex haidar on 7/18/26.
//
/* A task management and and notes polling class that pulls transcripted
 notes + transcript from the rep desktop app and adds them to the mobile
 app for use with the LiveActivity flashcards */
import Foundation
import Supabase
import SwiftUI


@MainActor
final class RepDesktopPoller: ObservableObject {
    private init() {}

    static let shared = RepDesktopPoller()
    private var task: Task<Void, Never>?
    
    func startPollingNotes() {
        task?.cancel()
        
        task = Task {
            while !Task.isCancelled {
                do {
                    try await getQueuedNotes()
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
    
    
    func getQueuedNotes() async throws {
        do {
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
            
            guard let firstNote = result.notes.first else { throw ErrorDesc.nilValue }

            let fullTranscript: String = firstNote.transcript ?? "no transcript"
            let fullNotes: String = firstNote.notes ?? "no notes"
            let userId: String = firstNote.id
            let createdAt: String = firstNote.created_at
            
            print("FULL TRANSCRIPT: \(fullTranscript)")
            print("FULL NOTES: \(fullNotes)")
            print("user id: \(userId) | created at: \(createdAt)")
            
        } catch {
            print("failed to get queued transcripted notes from rep desktop helper", ErrorDesc.callsiteError, error)
        }
    }
}

