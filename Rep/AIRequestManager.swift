//
//  AIRequestManager.swift
//  Rep
//
//  Created by alex haidar on 4/25/26.
//
// All requests to the supabase edge functions for the
// AI chatbox and audio transcription will be handled here
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
    
    
    public func openAIRequest(userMessage: String, gptModel: String = "mini", onChunk: @escaping(String) -> Void, onMeta: @escaping(String) -> Void) async throws {
        let openAIRequest: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        var urlRequest: URLRequest = URLRequest(url: openAIRequest)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        let messageBody: [String: Any] = ["input": userMessage, "model": gptModel]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        
        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: urlRequest)
            print("EDGE FUNCTION OPENAI RESPONSE: \(bytes)")
            
            for try await stream in bytes.lines {
                
                guard stream.hasPrefix("data:") else { continue }
                print(stream)
                let ssePayload = String(stream.dropFirst(6))    ///strip the "data:" field from the sse paylaod line
                if ssePayload == "[DONE]" { break }
                
                guard let streamData = ssePayload.data(using: .utf8) else { continue }
                let streamDecoder = try JSONDecoder().decode(StreamEvent.self, from: streamData)
                
                if streamDecoder.response != nil {
                    let meta = try await AIRequestManager.shared.extractChatMetadata(aiResponse: streamDecoder)
                    onMeta(meta)
                }
                
                guard streamDecoder.type == "response.output_text.delta", let delta = streamDecoder.delta else { continue }
                onChunk(delta)
            }
            
        } catch {
            print("failed to decode request from supabase", ErrorDesc.decodeError, error)
            throw ErrorDesc.decodeError
        }
    }
    
    
    public func extractChatMetadata(aiResponse: OpenAIStreamMeta) async throws -> String {
        let responseID: String = aiResponse.response?.id ?? "missing chat id"
        let responseStatus: String = aiResponse.response?.status ?? "missing status"
        let responseAIModel: String = aiResponse.response?.model ?? "missing ai model"
        
        return "extracted AI id: \(responseID) | status: \(responseStatus) | ai model: \(responseAIModel) ✅"
    }
    
    
    public func extractChatContent(extractedContent: String) throws -> String {      ///get titles and bullet lists from the json response body
        do {
            let data: Data = Data(extractedContent.utf8)
            let decodeParentResponse = JSONDecoder()
            let decodedTitlesAndBullets = try decodeParentResponse.decode(DecodedParentResponse.self, from: data)
            
            let formatContent: String = decodedTitlesAndBullets.sections.map { line in
                "\(line.title)\n" + line.bullets.map {" • \($0) "}.joined(separator: "\n") }.joined(separator: "\n")
            
            print("formatted titles and bullets: \(formatContent)")
            return formatContent
        } catch {
            print("failed to extract chat content ❗️", ErrorDesc.parsingError, error)
            throw ErrorDesc.nilValue
        }
    }
}



