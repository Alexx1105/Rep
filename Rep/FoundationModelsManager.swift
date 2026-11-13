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
    
    
    static func callFoundationModel(userMessage: String, ontextSnapshot: (String) -> Void, chatID: UUID) async throws -> String {
        checkModelAvailability()
        
        let options: GenerationOptions = GenerationOptions(temperature: 0.3, maximumResponseTokens: 4096)
        let session: LanguageModelSession = LanguageModelSession(model: SystemLanguageModel.default, instructions: promptConfig)
        let chatSessionContext = retainChatSessionContext(session: session, chatID: chatID)
        
        let responseStream: LanguageModelSession.ResponseStream = chatSessionContext.streamResponse(to: userMessage, options: options)
        print("context size:", SystemLanguageModel.default.contextSize)
        
        var answer: String = ""
        for try await text in responseStream {
            answer = text.content
            ontextSnapshot(answer)
        }
        return answer
    }
}

