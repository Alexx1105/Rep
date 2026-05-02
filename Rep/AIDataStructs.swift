//
//  AIDataStructs.swift
//  Rep
//
//  Created by alex haidar on 5/2/26.
//structs and types for all the AI features defined here


typealias OpenAIOutput = Parent.OpenAIResponse.Output
typealias OpenAIContent = Parent.OpenAIResponse.Output.Content

public struct Parent: Codable {
    public let openAIResponse: OpenAIResponse
    
    public struct OpenAIResponse: Codable, Identifiable {
        public let id: String
        public let status: String
        public let model: String
        public let output: [Output]
        
        public struct Output: Codable {
            public let type: String
            public let role: String
            public let content: [Content]
            
            public struct Content: Codable {
                public let type: String
                public let text: String
            }
        }
    }
}
