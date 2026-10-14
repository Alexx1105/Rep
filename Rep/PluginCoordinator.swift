//
//  PluginCoordinator.swift
//  Rep
//
//  Created by alex haidar on 10/10/26.
/* Middleware coordinator for calling backend
 data managers and oauth flows for plugins */
import Foundation
import SwiftData


@MainActor
final class PluginCoordinator: ObservableObject {
    static let shared = PluginCoordinator()
    let pluginRegistry = PluginRegistry.shared
    
    @Published private(set) var addedPluginId: Set<PluginRegistry.PluginId> = [] {
        didSet {
            UserDefaults.standard.set(addedPluginId.map { $0.rawValue }, forKey: "addedPluginId")
        }
    }
    
    private init() {
        let storedPluginIds = UserDefaults.standard.stringArray(forKey: "addedPluginId") ?? [PluginRegistry.PluginId.notion.rawValue]
        self.addedPluginId = Set(storedPluginIds.compactMap { PluginRegistry.PluginId(rawValue: $0) })
    }
    
    func addPluginToList(_ id: PluginRegistry.PluginId) {
        addedPluginId.insert(id)
    }
    
    func removePluginFromList(_ id: PluginRegistry.PluginId) {
        addedPluginId.remove(id)
    }
    
    
    func pluginConnectionRedirect(providerId: PluginRegistry.PluginId) async throws -> URL? {
        switch providerId {
        case .notion:
            guard let url: URL = URL(string: "https://api.notion.com/v1/oauth/authorize?client_id=138d872b-594c-8050-b985-0037723b58e0&response_type=code&owner=user&redirect_uri=https%3A%2F%2Foxgumwqxnghqccazzqvw.supabase.co%2Ffunctions%2Fv1%2Fauth-bridge") else { throw ErrorDesc.oauthError }
            return url
            
        case .googleDocs:
            guard let url: URL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=159023554096-v1gck09he80n7cgo1geslgmvotmqd2i3.apps.googleusercontent.com&response_type=code&redirect_uri=https%3A%2F%2Foxgumwqxnghqccazzqvw.supabase.co%2Ffunctions%2Fv1%2Fauth-bridge&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive.metadata.readonly%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdocuments.readonly&access_type=offline&prompt=consent") else { throw ErrorDesc.oauthError }
            return url
            
        case .obsidian:
            return nil      ///oauth is not required for obsidian imports
        }
    }
    
    
    func connectPluginProvider(providerId: PluginRegistry.PluginId, context: ModelContext, code: String, fileUrls: [URL]?) async throws {
        guard let provider = pluginRegistry.fetchPluginProvider(providerId: providerId) else { return }
        
        switch provider.id {
        case .notion:
            OAuthTokens.shared.storeModelContext(context)
            try await OAuthTokens.shared.exchangeToken(authorizationCode: code)
            try await NotionDataManager.shared.fetchFirstTimePages(context: context)
            
        case .googleDocs:
            //TODO: call oauth flow for googleDocs
            try await GoogleDocsDataManager.shared.fetchFirstTimePages(context: context, accessToken: "")  //pass token
            
        case .obsidian:
            guard let urls: [URL] = fileUrls, !urls.isEmpty else { throw ErrorDesc.fileProcessingError }
            try await ObsidianDataManager.shared.fetchFirstTimeMarkdownFiles(urls: urls, context: context)
        }
        addPluginToList(provider.id)
    }
}
