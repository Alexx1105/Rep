//
//  OauthProviderManager.swift
//  MuscleMemory
//
//  Created by alex haidar on 12/7/24.
//
import Foundation
import SwiftData


public class OauthProviderManager: ObservableObject {
    static let shared = OauthProviderManager()
    
    @Published public var personEmail: String?
    @Published public private(set) var didReceiveGoogleCallback: Bool = false
    
    var modelContext: ModelContext!
    public func storeModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    private struct OAuthBridgeRequest: Encodable {
        let action: String
        let provider: String?
        let handoff_code: String?
    }
    
    private struct OAuthAuthorizationResponse: Decodable {
        let provider: String
        let authorization_url: URL
        let state: String
    }
    
    private struct OAuthTokenResponse: Decodable {
        let provider: String
        let access_token: String
        let expires_in: Int
        let token_type: String
        let scope: String?
        let picked_file_ids: [String]?
    }
    
    
    @MainActor
    func notionAuthorizationURL() async throws -> URL {
        let body: OAuthBridgeRequest = OAuthBridgeRequest(action: "notion_start", provider: nil, handoff_code: nil)
        let data: Data = try await oauthBridgeRequest(body: body)
        
        let jsonDecoder: JSONDecoder = JSONDecoder()
        let authorization: OAuthAuthorizationResponse = try jsonDecoder.decode(OAuthAuthorizationResponse.self, from: data)
        let components: URLComponents? = URLComponents(url: authorization.authorization_url, resolvingAgainstBaseURL: false)
        
        guard authorization.provider == "notion", !authorization.state.isEmpty,
              components?.scheme == "https", components?.host == "api.notion.com",
              components?.path == "/v1/oauth/authorize",
              components?.queryItems?.first(where: { $0.name == "state" })?.value == authorization.state else { throw ErrorDesc.oauthError }
        return authorization.authorization_url
    }
    
    
    @MainActor
    static func notionHandoffCode(from url: URL) throws -> String? {
        guard url.scheme?.lowercased() == "musclememory.kimchilabs.com", url.host == "callback",
              
                let components: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let queryItems: [URLQueryItem] = components.queryItems ?? []
        
        guard queryItems.first(where: { $0.name == "provider" })?.value == "notion" else { return nil }
        guard !queryItems.contains(where: { $0.name == "error" }) else { throw ErrorDesc.oauthError }
        
        let handoffs: [URLQueryItem] = queryItems.filter { $0.name == "handoff" }
        guard handoffs.count == 1, let handoffCode: String = handoffs.first?.value, !handoffCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ErrorDesc.oauthError }
        return handoffCode
    }
    
    
    @MainActor
    public func notionExchangeToken(handoffCode: String) async throws {
        guard !handoffCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let context: ModelContext = modelContext else { throw ErrorDesc.oauthError }
        let body: OAuthBridgeRequest = OAuthBridgeRequest(action: "redeem_handoff", provider: "notion", handoff_code: handoffCode)
        let data: Data = try await oauthBridgeRequest(body: body)
        
        let jsonDecoder: JSONDecoder = JSONDecoder()
        
        let tokenResponse: OAuthTokenResponse = try jsonDecoder.decode(OAuthTokenResponse.self, from: data)
        guard tokenResponse.provider == "notion", !tokenResponse.access_token.isEmpty, tokenResponse.token_type.lowercased() == "bearer" else { throw ErrorDesc.authTokenError }
        let providerId: String = "notion"
        
        let desc: FetchDescriptor<AuthToken> = FetchDescriptor<AuthToken>(predicate: #Predicate { $0.providerId == providerId })
        let storedTokens: [AuthToken] = try context.fetch(desc)
        
        if let token: AuthToken = storedTokens.first {
            token.accessToken = tokenResponse.access_token
            for duplicate: AuthToken in storedTokens.dropFirst() {
                context.delete(duplicate)
            }
        } else {
            let token: AuthToken = AuthToken(accessToken: tokenResponse.access_token, providerId: providerId)
            context.insert(token)
        }
        try context.save()
    }
    
    
    @MainActor
    private func oauthBridgeRequest(body: OAuthBridgeRequest) async throws -> Data {
        let accessToken: String = try await supabaseDBClient.auth.session.accessToken
        guard !accessToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        let endpoint: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/auth-bridge")!
        var request: URLRequest = URLRequest(url: endpoint)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else { throw ErrorDesc.oauthError }
        return data
    }
    
    
    @MainActor
    func googleDocsAuthorizationURL() async throws -> URL {
        self.didReceiveGoogleCallback = false
        let body: OAuthBridgeRequest = OAuthBridgeRequest(action: "google_start", provider: nil, handoff_code: nil)
        let data: Data = try await oauthBridgeRequest(body: body)
        
        let jsonDecoder: JSONDecoder = JSONDecoder()
        let authorization: OAuthAuthorizationResponse = try jsonDecoder.decode(OAuthAuthorizationResponse.self, from: data)
        let components: URLComponents? = URLComponents(url: authorization.authorization_url, resolvingAgainstBaseURL: false)
        
        guard authorization.provider == "google", !authorization.state.isEmpty,
              components?.scheme == "https", components?.host == "accounts.google.com",
              components?.path == "/o/oauth2/v2/auth",
              components?.queryItems?.first(where: { $0.name == "state" })?.value == authorization.state else { throw ErrorDesc.oauthError }
        return authorization.authorization_url
    }
    
    
    @MainActor
    static func googleDocsHandoffCode(from url: URL) throws -> String? {
        guard url.scheme?.lowercased() == "musclememory.kimchilabs.com", url.host == "callback",
              
                let components: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let queryItems: [URLQueryItem] = components.queryItems ?? []
        
        guard queryItems.first(where: { $0.name == "provider" })?.value == "google" else { return nil }
        shared.didReceiveGoogleCallback = true
        guard !queryItems.contains(where: { $0.name == "error" }) else { throw ErrorDesc.oauthError }
        
        let handoffs: [URLQueryItem] = queryItems.filter { $0.name == "handoff" }
        guard handoffs.count == 1, let handoffCode: String = handoffs.first?.value, !handoffCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ErrorDesc.oauthError }
        return handoffCode
    }
    
    
    @MainActor
    public func googleDocsExchangeToken(handoffCode: String) async throws -> [String] {
        guard !handoffCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let context: ModelContext = modelContext else { throw ErrorDesc.oauthError }
        let body: OAuthBridgeRequest = OAuthBridgeRequest(action: "redeem_handoff", provider: "google", handoff_code: handoffCode)
        let data: Data = try await oauthBridgeRequest(body: body)
        
        let jsonDecoder: JSONDecoder = JSONDecoder()
        
        let tokenResponse: OAuthTokenResponse = try jsonDecoder.decode(OAuthTokenResponse.self, from: data)
        guard tokenResponse.provider == "google", !tokenResponse.access_token.isEmpty, tokenResponse.token_type.lowercased() == "bearer" else { throw ErrorDesc.authTokenError }
        guard let pageIDs: [String] = tokenResponse.picked_file_ids, !pageIDs.isEmpty,
              pageIDs.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw ErrorDesc.fileProcessingError }
        let providerId: String = "googleDocs"
        
        let desc: FetchDescriptor<AuthToken> = FetchDescriptor<AuthToken>(predicate: #Predicate { $0.providerId == providerId })
        let storedTokens: [AuthToken] = try context.fetch(desc)
        
        if let token: AuthToken = storedTokens.first {
            token.accessToken = tokenResponse.access_token
            for duplicate: AuthToken in storedTokens.dropFirst() {
                context.delete(duplicate)
            }
            
        } else {
            let token: AuthToken = AuthToken(accessToken: tokenResponse.access_token, providerId: providerId)
            context.insert(token)
        }
        try context.save()
        return pageIDs
    }
    
    
    @MainActor
    public func googleDocsAccessToken(context: ModelContext) async throws -> String {
        let body: OAuthBridgeRequest = OAuthBridgeRequest(action: "google_access_token", provider: "google", handoff_code: nil)
        let data: Data = try await oauthBridgeRequest(body: body)
        
        let jsonDecoder: JSONDecoder = JSONDecoder()
        let tokenResponse: OAuthTokenResponse = try jsonDecoder.decode(OAuthTokenResponse.self, from: data)
        guard tokenResponse.provider == "google", !tokenResponse.access_token.isEmpty, tokenResponse.token_type.lowercased() == "bearer" else { throw ErrorDesc.authTokenError }
        let providerId: String = "googleDocs"
        
        let desc: FetchDescriptor<AuthToken> = FetchDescriptor<AuthToken>(predicate: #Predicate { $0.providerId == providerId })
        let storedTokens: [AuthToken] = try context.fetch(desc)
        
        if let token: AuthToken = storedTokens.first {
            token.accessToken = tokenResponse.access_token
            for duplicate: AuthToken in storedTokens.dropFirst() {
                context.delete(duplicate)
            }
        } else {
            let token: AuthToken = AuthToken(accessToken: tokenResponse.access_token, providerId: providerId)
            context.insert(token)
        }
        try context.save()
        return tokenResponse.access_token
    }
}
