//
//  AudioTranscriptionManager.swift
//  Rep
//
//  Created by alex haidar on 6/7/26.
//
/* All requests to the supabase edge functions for the Voice
   transcription with gpt-4o-mini-transcribe or future models will be handled here  */


import Foundation
import Supabase


public final class AudioTranscriptionManager: ObservableObject {
    public init() {}
    public static let AudioTranscription = AudioTranscriptionManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    typealias MessageTranscription = URLSessionWebSocketTask.Message
    
    @Published var liveTranscription: String = ""
    @Published var finishedTranscript: String = ""
    @Published var isTranscribing: Bool = false
    
    
    public func openAudioSession() async throws -> AudioSession.SessionData {
        
        let url: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat-dev")!
        var urlRequest: URLRequest = URLRequest(url: url)
        
        let session = try await supabaseDBClient.auth.session
        let supabaseAccessToken: String = session.accessToken
        guard !supabaseAccessToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        urlRequest.setValue("Bearer \(supabaseAccessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("audio", forHTTPHeaderField: "x-rep-action")
        urlRequest.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print("SESSION DATA ✅: \(data)")
            
            guard let urlResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
            let _ = String(data: data, encoding: .utf8)
            
            guard (200...299).contains(urlResponse.statusCode) else { throw ErrorDesc.urlResponseError }
            
            let decodeSession = try JSONDecoder().decode(AudioSession.self, from: data)
            return decodeSession.session
            
        } catch {
            print("error opening audio session", ErrorDesc.sessionError, error)
        }
        throw ErrorDesc.sessionError
    }
    
    
    public func startAudioStream(session: AudioSession.SessionData) async throws {
        do {
            let ephemeralSecret: String = session.value
            guard !ephemeralSecret.isEmpty else { throw ErrorDesc.nilValue }
            
            let openaiTranscriptionUrl: URL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
            var urlRequest: URLRequest = URLRequest(url: openaiTranscriptionUrl)
            
            urlRequest.setValue("Bearer \(ephemeralSecret)", forHTTPHeaderField: "Authorization")
            
            let createSocket = URLSession.shared.webSocketTask(with: urlRequest)
            self.webSocketTask = createSocket
            
            createSocket.resume()
            
            await MainActor.run {
                isTranscribing = true
            }
            
            Task {
                try await transcriptionEventListener()
            }
            
            print("web socket for audio stream successfully created...")
        } catch {
            print("failed to start stream to openai transcription endpoint", ErrorDesc.webSocketError, error)
        }
    }
    
    
    public func decodeTranscriptionResponse() async throws -> TranscriptionStream {
        guard let webSocketTask else { throw ErrorDesc.webSocketError }
        
        let streamMessage: MessageTranscription = try await webSocketTask.receive()
        
        switch streamMessage {
            
        case .data(let data):
            return try JSONDecoder().decode(TranscriptionStream.self, from: data)
            
        case .string(let text):
            guard let text = text.data(using: .utf8) else { throw ErrorDesc.encodeError }
            return try JSONDecoder().decode(TranscriptionStream.self, from: text)
            
        @unknown default:
            throw ErrorDesc.decodeError
        }
    }
    
    
    public func extractTranscriptionResponse() async throws {
        
        do {
            let response = try await decodeTranscriptionResponse()
            
            try await MainActor.run {
                
                if response.type == "error" { throw ErrorDesc.extractError }
                
                switch response.type {
                case "conversation.item.input_audio_transcription.delta":
                    if let delta = response.delta {
                        self.liveTranscription += delta
                    }
                    
                case "conversation.item.input_audio_transcription.completed":
                    if let text = response.transcript {
                        self.finishedTranscript += text
                    }
                    
                default:
                    break
                }
            }
            
            print("successfully appended deltas into transcipt ✅", liveTranscription)
        } catch {
            print("error extracting objects from transcript", ErrorDesc.extractError, error)
            throw ErrorDesc.extractError
        }
    }
    
    
    public func stopAudioStream() async throws {
        webSocketTask?.cancel(with: .normalClosure, reason: .none)
        webSocketTask = nil
        isTranscribing = false
        
    }
    
    public func transcriptionEventListener() async throws {
        
         do {
             while webSocketTask != nil {
                 try await extractTranscriptionResponse()
             }
         } catch {
             print("audio stream interrupted ❗️", ErrorDesc.webSocketError, error)
         }
    }
}
