//
//  AIDataStructs.swift
//  Rep
//
//  Created by alex haidar on 5/2/26.
/* structs and types for all the AI features defined here */



public typealias OpenAIStreamMeta = StreamEvent
typealias TitleAndBulletContent = DecodedParentResponse


public struct StreamEvent: Decodable {
    public let type: String
    public let delta: String?
    public let response: StreamResponse?
    
    public struct StreamResponse: Decodable {
        public let id: String
        public let status: String
        public let model: String
    }
}

public struct DecodedParentResponse: Codable {        ///get titles and bullet lists from the json response body
    public let sections: [Section]
    
    public struct Section: Codable {
        public let title: String
        public let bullets: [String]
    }
}


public struct AudioSession: Decodable {             ///for audio trnascription
    let session: SessionData
    
    public struct SessionData: Decodable {
        let value: String
        let expires_at: Int
        let session: SessionTypes
        
        public struct SessionTypes: Decodable {
            let type: String
            let id: String
        }
    }
}

public struct TranscriptionStream: Decodable {
    let type: String
    let item_id: String?
    let content_index: Int?
    let delta: String?
    let transcript: String?
    
}
