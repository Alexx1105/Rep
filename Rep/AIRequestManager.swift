//
//  AIRequestManager.swift
//  Rep
//
//  Created by alex haidar on 4/25/26.
//
/* All requests to the supabase edge functions for the AI chatbox and audio transcription will be handled here  */
import Foundation
import Supabase
import SwiftData


@MainActor
public final class AIRequestManager: ObservableObject {
    @Published public private(set) var isNotesGenerated: Bool = false
    public static let shared = AIRequestManager()
    private init() {}
    
    struct aiModels: Codable {
        let userMessage: String
        let gptModel: String
        let userFile: [URL]
    }
    
    enum modelTier: Codable {
        case gptMini
        case gptFull
    }
    
    
    public func buildFilePathHelper(userFileUrl: URL, fileIdentifier: String) throws -> Data {
        let fileName: String = userFileUrl.lastPathComponent
        let fileData: Data = try Data(contentsOf: userFileUrl)
        let getMIME = guessMimeType(for: fileData)
        
        var fileBody = Data()
        
        fileBody.append("--\(fileIdentifier)\r\n".data(using: .utf8)!)
        fileBody.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        fileBody.append("Content-Type: \(getMIME)\r\n\r\n".data(using: .utf8)!)
        fileBody.append(fileData)
        fileBody.append("\r\n".data(using: .utf8)!)
        
        print("file body built: \(fileBody)")
        return fileBody
    }
    
    
    public func buildPhotoBodyHelper(userPhotoData: Data, fileIdentifier: String) throws -> Data {
        let photoMime: String = guessMimeType(for: userPhotoData)
        
        var photoBody = Data()
        
        photoBody.append("--\(fileIdentifier)\r\n".data(using: .utf8)!)
        photoBody.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(photoMime)\"\r\n".data(using: .utf8)!)
        photoBody.append("Content-Type: \(photoMime)\r\n\r\n".data(using: .utf8)!)
        photoBody.append(userPhotoData)
        photoBody.append("\r\n".data(using: .utf8)!)
        
        return photoBody
    }
    
    
    public func openAIRequest(userMessage: String, userFileUrl: URL?, userPhotoData: Data?, gptModel: String = "mini", context: ModelContext, onChunk: @escaping(String) async -> Void, onMeta: @escaping(String) -> Void) async throws {
        let fileIdentifier: String = UUID().uuidString
        
        let openAIRequest: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        var urlRequest: URLRequest = URLRequest(url: openAIRequest)
        
        let session = try await supabaseDBClient.auth.session
        let supabaseAccessToken: String = session.accessToken
        
        guard !supabaseAccessToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        urlRequest.setValue("multipart/form-data; boundary=\(fileIdentifier)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(supabaseAccessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = "POST"
        
        var multipartReqBody: Data = Data()
        
        multipartReqBody.append("--\(fileIdentifier)\r\n".data(using: .utf8)!)
        multipartReqBody.append("Content-Disposition: form-data; name=\"input\"\r\n\r\n".data(using: .utf8)!)
        multipartReqBody.append("\(userMessage)\r\n".data(using: .utf8)!)
        
        multipartReqBody.append("--\(fileIdentifier)\r\n".data(using: .utf8)!)
        
        multipartReqBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        multipartReqBody.append("\(gptModel)\r\n".data(using: .utf8)!)
        
        if let userFileUrl {
            let fileBytes = try buildFilePathHelper(userFileUrl: userFileUrl, fileIdentifier: fileIdentifier)
            multipartReqBody.append(fileBytes)
        }
        
        if let userPhotoData {
            let photoBytes = try buildPhotoBodyHelper(userPhotoData: userPhotoData, fileIdentifier: fileIdentifier)
            multipartReqBody.append(photoBytes)
        }
        
        multipartReqBody.append("--\(fileIdentifier)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = multipartReqBody
        
        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: urlRequest)
            print("EDGE FUNCTION OPENAI RESPONSE: \(bytes)")
            
            for try await stream in bytes.lines {
                
                guard stream.hasPrefix("data:") else { continue }
                let ssePayload = String(stream.dropFirst(6))    ///strip the "data:" field from the sse payload line
                if ssePayload == "[DONE]" { break }
                
                guard let streamData = ssePayload.data(using: .utf8) else { continue }
                let streamDecoder = try JSONDecoder().decode(StreamEvent.self, from: streamData)
                
                if streamDecoder.response != nil {
                    let meta = try await AIRequestManager.shared.extractChatMetadata(aiResponse: streamDecoder, context: context)
                    onMeta(meta)
                }
                guard streamDecoder.type == "response.output_text.delta", let delta = streamDecoder.delta else { continue }
                await onChunk(delta)
            }
            
        } catch {
            print("failed to decode request from supabase", ErrorDesc.decodeError, error)
            throw ErrorDesc.decodeError
        }
        self.isNotesGenerated = true
    }
    
    
    public func extractChatMetadata(aiResponse: OpenAIStreamMeta, context: ModelContext) async throws -> String {
        let responseID: String = aiResponse.response?.id ?? "missing chat id"
        let responseStatus: String = aiResponse.response?.status ?? "missing status"
        let responseAIModel: String = aiResponse.response?.model ?? "missing ai model"
        
        do {
            let metaContent: OpenAIMeta = OpenAIMeta(id: responseID, model: responseAIModel, status: responseStatus)
            context.insert(metaContent)
            try context.save()
            
        } catch {
            print("error saving chat metadata", ErrorDesc.persistenceError, error)
        }
        return "extracted AI id: \(responseID) | status: \(responseStatus) | ai model: \(responseAIModel) ✅"
    }
    
    
    public func upsertChatContent(fullSnapshot: String, openaiID: String, title: String) async throws {
        
        do {
            let token: String = await PushTokenManager.generatePushToken()
            guard !fullSnapshot.isEmpty && !openaiID.isEmpty && !title.isEmpty && !token.isEmpty else { throw ErrorDesc.nilValue }
            let chunks: [String] = fullSnapshot.components(separatedBy: .newlines)
            
            for chunk in chunks {
                let content: String = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { continue }
                
                await SupabaseClientManager.shared.supabaseOpenaiChatUpsert(openaiID: openaiID, title: title, content: content, token: token)
                print("==========================\neach chunk: \(chunk)")
            }
            
            print("openai chat successfully upserted into supabase ✅")
        } catch {
            print("openai chat did not get upserted into supabase ❗️", ErrorDesc.persistenceError, error)
        }
    }
}

