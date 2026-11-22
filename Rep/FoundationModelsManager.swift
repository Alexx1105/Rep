//
//  FoundationModelsManager.swift
//  Rep
//
//  Created by alex haidar on 11/8/26.
/* Manager class that handles requests and config
 for apple intelligence AFM (3rd gen) local models */
import Foundation
import FoundationModels


@MainActor
final class FoundationModelsManager {
    private static var managers: [UUID: FoundationModelsManager] = [:]
    
    private let session: LanguageModelSession
    private init(session: LanguageModelSession) {
        self.session = session
        session.prewarm()
    }
    
    static func prewarmIfAvailable(chatID: UUID) {
        guard case .available = SystemLanguageModel.default.availability else { return }
        _ = manager(for: chatID)
    }
    
    private static func manager(for chatID: UUID) -> FoundationModelsManager {
        if let existingManager = managers[chatID] {
            return existingManager
        }
        
        let session = LanguageModelSession(model: SystemLanguageModel.default, instructions: promptConfig)
        let manager = FoundationModelsManager(session: session)
        managers[chatID] = manager
        return manager
    }
    
    
    static func callFoundationModel(userMessage: String, userFileUrl: [URL]?, userPhotoData: [Data] = [], ontextSnapshot: (String) -> Void, chatID: UUID) async throws -> String {
        let options: GenerationOptions = GenerationOptions(temperature: 0.3, maximumResponseTokens: 4096)
        let session = manager(for: chatID).session
        
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
        
        let responseStream: LanguageModelSession.ResponseStream = session.streamResponse(to: prompt, options: options)
        
        var answer: String = ""
        for try await text in responseStream {
            answer = text.content
            ontextSnapshot(answer)
        }
        return answer
    }
}

