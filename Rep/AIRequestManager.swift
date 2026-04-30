//
//  AIRequestManager.swift
//  Rep
//
//  Created by alex haidar on 4/25/26.
//All requests to the supabase edge functions for the AI chatbox and audio transcription will be handled here
import Foundation
import Supabase


public final class AIRequestManager: ObservableObject {
    public static let shared = AIRequestManager()
    private init() {}
    
    struct aiModels: Codable {
        let userMessage: String
        let gptModel: String
    }
    
    enum modelTier: Codable {
        case gptMini
        case gptFull
    }
    
    public func openAIRequest(userMessage: String, gptModel: String = "mini") async throws -> String {        ///openAI API accessed via supabase edge function
        let openAIRequest: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        var urlRequest: URLRequest = URLRequest(url: openAIRequest)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        let messageBody: [String: Any] = ["input": userMessage, "model": gptModel]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)       //TODO: add response if we acc need it
            print("EDGE FUNCTION OPENAI RESPONSE: \(data)")
            
            guard !data.isEmpty else { return "" }
            
            guard let encodeData: String = String(data: data, encoding: .utf8) else { throw ErrorDesc.encodeError }
            print("encoded data from edge function \(encodeData)")
            
            let decodeRespose = JSONDecoder()
            decodeRespose.dateDecodingStrategy = .custom { decoder in
                let c = try decoder.singleValueContainer()
                let dateString = try c.decode(String.self)
                
                let format = ISO8601DateFormatter()
                format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
                
                if let date: Date = format.date(from: dateString) { return date }
                
                format.formatOptions = [.withInternetDateTime]
                if let dateTime = format.date(from: dateString) { return dateTime }
                
                throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: c.codingPath, debugDescription: "Date string does not match expected format"))
            }
            
            let openAIResponse: String = String(data: data, encoding: .utf8) ?? "empty response"
            print("OPENAI API RESPONSE: \(openAIResponse)")
            return openAIResponse
            
        } catch {
            print("failed to decode request from supabase", ErrorDesc.decodeError, error)
        }
        return ""
    }
}

