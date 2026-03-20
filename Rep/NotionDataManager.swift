//
//  NotionDataManager.swift
//  Rep
//
//  Created by alex haidar on 3/16/26.
//
import Foundation
import SwiftData


public struct NotionSearchRequest: Codable {
    public let results: [result]
    public let object: String?
    
    public struct result: Codable {
        public let id: String?
        public let object: String?
        public let properties: properties?
        public let icon: Icon?
        public let last_edited_time: Date?
        public let created_time: Date?
    }
    
    public struct Icon: Codable {
        public let type: String?
        public let emoji: String?
    }
    
    public struct properties: Codable {
        public let title: TitleDict?
    }
    
    public struct TitleDict: Codable {
        public let title: [TitleItem]
    }
    public struct TitleItem: Codable {
        public let plain_text: String?
    }
}

@Model final class NotionPageMetaData {                 ///Notion page metadata schema for on-demand syncing/retrieval feature
    @Attribute(.unique) public var pageID: String
    
    var pageTitle: String
    var lastEditedAt: Date
    var lastFetchedAt: Date
    var isAutoSync: Bool
    var plain_text: String
    
    init(pageID: String, pageTitle: String, lastEditedAt: Date, lastFetchedAt: Date, isAutoSync: Bool, plain_text: String) {
        self.pageID = pageID
        self.pageTitle = pageTitle
        self.lastEditedAt = lastEditedAt
        self.lastFetchedAt = lastFetchedAt
        self.isAutoSync = isAutoSync
        self.plain_text = plain_text
    }
}


class NotionDataManager: ObservableObject {
    static let shared = NotionDataManager()
    
    @Published var plain_text: String?
    @Published var id: String
    
    enum ErrorDesc: LocalizedError {        ///start using this for logging local errors
        case authTokenError
        case urlRequestError
        case parsingError
        case encodeError
    }
    
    @MainActor
    public func fetchAuthToken(context: ModelContext) throws -> String {
        let fetchDescriptor = FetchDescriptor<AuthToken>()
        let authToken = try context.fetch(fetchDescriptor)
        
        guard let token = authToken.first?.accessToken else { throw ErrorDesc.authTokenError }
        return token
    }
    
    let searchEndpoint: URL = URL(string: "https://api.notion.com/v1/search")
    private init(id: String) {
        self.id = id
    }
    
    
    private func getHeaders(token: String) async throws {
        guard !token.isEmpty else { throw ErrorDesc.authTokenError }
        
        let passToken = try fetchAuthToken(context: token)
        var urlRequest = URLRequest(url: searchEndpoint)
        
        guard let req = urlRequest as URLRequest else { throw ErrorDesc.urlRequestError }
        req.addValue("Bearer \(passToken)", forHTTPHeaderField: "Authorization")
        req.addValue("2026-03-11", forHTTPHeaderField: "Notion-Version")
        
        do {
            req.httpMethod = "POST"
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
            
            guard let encodeData = String(data: data, encoding: .utf8) else { throw ErrorDesc.encodeError }
            let decodePageData = JSONDecoder()
            decodePageData.dateDecodingStrategy = .custom { decoder in
                
                let c = try decoder.singleValueContainer()
                let dateString = try c.decode(String.self)
                
                let format = ISO8601DateFormatter()
                format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
                
                if let date = format.date(from: dateString) { return date }
                
                format.formatOptions = [.withInternetDateTime]
                if let dateTime = format.date(from: dateString) { return dateTime }
                
                throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: c.codingPath,
                                                                                  debugDescription: "Date string does not match expected format"))
                let decodePage = try decoderPageData.decode(NotionSearchRequest.self, from: data)
            }
            
            for i in decodePage.results {
                print("RESULTS: \(i)")
            }
            
            
        } catch {
            print("parsing error: \(ErrorDesc.parsingError)")
        }
    }
}


