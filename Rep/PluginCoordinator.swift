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
            return try await OauthProviderManager.shared.notionAuthorizationURL()
            
        case .googleDocs:
            return try await OauthProviderManager.shared.googleDocsAuthorizationURL()
            
        case .obsidian:
            return nil      ///oauth is not required for obsidian imports
        }
    }
    
    
    func connectPluginProvider(providerId: PluginRegistry.PluginId, context: ModelContext, code: String, fileUrls: [URL]?) async throws {
        guard let provider = pluginRegistry.fetchPluginProvider(providerId: providerId) else { return }
        
        switch provider.id {
        case .notion:
            OauthProviderManager.shared.storeModelContext(context)
            try await OauthProviderManager.shared.notionExchangeToken(handoffCode: code)
            try await NotionDataManager.shared.fetchFirstTimePages(context: context)
            
        case .googleDocs:
            OauthProviderManager.shared.storeModelContext(context)
            let pageIDs: [String] = try await OauthProviderManager.shared.googleDocsExchangeToken(handoffCode: code)
            let accessToken: String = try FetchAuth.fetchAuthToken(providerId: "googleDocs")
            try await GoogleDocsDataManager.shared.fetchFirstTimePages(pageIDs: pageIDs, context: context, accessToken: accessToken)
            
        case .obsidian:
            guard let urls: [URL] = fileUrls, !urls.isEmpty else { throw ErrorDesc.fileProcessingError }
            try await ObsidianDataManager.shared.fetchFirstTimeMarkdownFiles(urls: urls, context: context)
        }
        addPluginToList(provider.id)
    }
}
