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
    
    
    public func openAIRequest(userMessage: String, gptModel: String = "mini") async throws -> Parent {           ///openAI API accessed via supabase edge function
        let openAIRequest: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        var urlRequest: URLRequest = URLRequest(url: openAIRequest)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        let messageBody: [String: Any] = ["input": userMessage, "model": gptModel]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            print("EDGE FUNCTION OPENAI RESPONSE: \(data)")
            
            guard !data.isEmpty else { throw ErrorDesc.responseError }
            
            guard let encodeData: String = String(data: data, encoding: .utf8) else { throw ErrorDesc.encodeError }
            print("encoded data from edge function \(encodeData)")
            
            let decodeRespose: JSONDecoder = JSONDecoder()
            let aiResponse: Parent = try decodeRespose.decode(Parent.self, from: data)
            
            print("returned decoded openAI response: \(aiResponse)")
            return aiResponse
        } catch {
            print("failed to decode request from supabase", ErrorDesc.decodeError, error)
            throw ErrorDesc.decodeError
        }
    }
    
    
    public func extractChatMetadata(aiResponse: Parent) throws -> String {
        do {
            guard let accessParent: OpenAIOutput = aiResponse.openAIResponse.output.first else { throw ErrorDesc.nilValue }
            guard let aiText: OpenAIContent = accessParent.content.first else { throw ErrorDesc.nilValue }
            
            let responseID: String = aiResponse.openAIResponse.id
            let responseStatus: String = aiResponse.openAIResponse.status
            let responseAIModel: String = aiResponse.openAIResponse.model
            
            print("extracted AI id: \(responseID) | status: \(responseStatus) | ai model: \(responseAIModel)")
            return aiText.text
        } catch {
            print("failed to extract chat metadata❗️", ErrorDesc.parsingError, error)
        }
        throw ErrorDesc.parsingError
    }
    
    
    public func extractChatContent(extractedContent: String) throws -> String {      ///get titles and bullet lists from the json response body
        do {
            let data: Data = Data(extractedContent.utf8)
            let decodeParentResponse = JSONDecoder()
            let decodedTitlesAndBullets = try decodeParentResponse.decode(DecodedParentResponse.self, from: data)
            
            let formatContent: String = decodedTitlesAndBullets.sections.map { line in
                "\(line.title)\n" + line.bullets.map {" •\($0) "}.joined(separator: "\n") }.joined(separator: "\n")
            
            print("formatted titles and bullets: \(formatContent)")
            return formatContent
        } catch {
            print("failed to extract chat content ❗️", ErrorDesc.parsingError, error)
            throw ErrorDesc.nilValue
        }
    }
}



