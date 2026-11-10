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
    static func callFoundationModel(userMessage: String, ontextSnapshot: (String) -> Void) async throws -> String {
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
        
        let options: GenerationOptions = GenerationOptions(temperature: 0.3, maximumResponseTokens: 1500)
        let session: LanguageModelSession = LanguageModelSession(model: SystemLanguageModel.default, instructions: promptConfig)
        let responseStream: LanguageModelSession.ResponseStream = session.streamResponse(to: userMessage, options: options)
        
        var answer: String = ""
        for try await text in responseStream {
            answer = text.content
            ontextSnapshot(answer)
        }
        return answer
    }
}

