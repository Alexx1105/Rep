//
//  FoundationModelsManager.swift
//  Rep
//
//  Created by alex haidar on 11/8/26.
/* Manager class that handles requests and config
 for apple intelligence AFM (3rd gen) local models */
import Foundation
import FoundationModels

//TODO: add support for prewarming

@MainActor
final class FoundationModelsManager {
    private static var allSessions: [UUID : LanguageModelSession] = [:]
    
    
    private static func checkModelAvailability() {
        var isModelAvailable: Bool {
            switch SystemLanguageModel.default.availability {
            case .available:
                print("model is available")
                return true
            case .unavailable:
                print("apple intelligence AFM model is not available")
                return false
            }
        }
    }

    
    private static func retainChatSessionContext(session: LanguageModelSession, chatID: UUID) -> LanguageModelSession {
        if let existingSession = allSessions[chatID] {
            return existingSession
        }
        allSessions[chatID] = session
        return session
    }
    
    
    static func callFoundationModel(userMessage: String, userFileUrl: [URL]?, userPhotoData: [Data] = [], ontextSnapshot: (String) -> Void, chatID: UUID) async throws -> String {
        checkModelAvailability()
        
        let options: GenerationOptions = GenerationOptions(temperature: 0.3, maximumResponseTokens: 4096)
        let session: LanguageModelSession = LanguageModelSession(model: SystemLanguageModel.default, instructions: promptConfig)
        let chatSessionContext = retainChatSessionContext(session: session, chatID: chatID)

        var prompt = userMessage
        for fileURL in userFileUrl ?? [] {
            let documentText: String
            switch fileURL.pathExtension.lowercased() {
            case "pdf":
                do {
                    documentText = try await fileExtractor(fileUrl: fileURL, fileFormat: .pdfText)
                } catch ErrorDesc.pdfExtractionError {
                    documentText = try await fileExtractor(fileUrl: fileURL, fileFormat: .pdfImageOcr)
                }
            case "txt", "md", "csv", "tsv":
                documentText = try await fileExtractor(fileUrl: fileURL, fileFormat: .plaintext)    ///maybe add another type of decoding fallback for failure-proof hardening
            case "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff":
                documentText = try await fileExtractor(fileUrl: fileURL, fileFormat: .photoImage)
            default:
                throw ErrorDesc.decodeError
            }
            prompt += "\n\nSource document: \(fileURL.lastPathComponent)\n\(documentText)\nEnd of source document."
        }

        for (index, photoData) in userPhotoData.enumerated() {
            try Task.checkCancellation()
            let photoText = try await photoTextExtractor(photoData: photoData)
            prompt += "\n\nSource photo \(index + 1):\n\(photoText)\nEnd of source photo."
        }
        
        let responseStream: LanguageModelSession.ResponseStream = chatSessionContext.streamResponse(to: prompt, options: options)
        
        var answer: String = ""
        for try await text in responseStream {
            answer = text.content
            ontextSnapshot(answer)
        }
        return answer
    }
}

