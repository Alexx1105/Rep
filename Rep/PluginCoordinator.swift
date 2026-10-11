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
    
    
    func connectPluginProvider(providerId: PluginRegistry.PluginId, context: ModelContext, code: String) async throws {  //TODO: call auth + data manager flows for rest of providers
        guard let provider = pluginRegistry.fetchPluginProvider(providerId: providerId) else { return }
        
        switch provider.id {
        case .notion:
            OAuthTokens.shared.storeModelContext(context)
            try await OAuthTokens.shared.exchangeToken(authorizationCode: code)
            try await NotionDataManager.shared.fetchFirstTimePages(context: context)
            
        case .googleDocs:
            throw ErrorDesc.pluginError
        case .obsidian:
            throw ErrorDesc.pluginError
        case .oneNote:
            throw ErrorDesc.pluginError
        default:
            throw ErrorDesc.pluginError
        }
        addPluginToList(provider.id)
    }
    
    
    func pluginConnectionRedirect(providerId: PluginRegistry.PluginId) async throws -> URL {
        switch providerId {
        case .notion:
            guard let url: URL = URL(string: "https://api.notion.com/v1/oauth/authorize?client_id=138d872b-594c-8050-b985-0037723b58e0&response_type=code&owner=user&redirect_uri=https%3A%2F%2Foxgumwqxnghqccazzqvw.supabase.co%2Ffunctions%2Fv1%2Fauth-bridge") else { throw ErrorDesc.pluginError }
            return url
            
        case .googleDocs, .obsidian, .oneNote:
            throw ErrorDesc.pluginError         //TODO: add the rest of the oauth url redirects here
        }
    }
}
