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
        let storedPluginIds = UserDefaults.standard.stringArray(forKey: "addedPluginId") ?? []
        self.addedPluginId = Set(storedPluginIds.compactMap { PluginRegistry.PluginId(rawValue: $0) })
    }
    
    func addPluginToList(_ id: PluginRegistry.PluginId) {
        addedPluginId.insert(id)
    }
    
    
    func connectPluginProvider(providerId: PluginRegistry.PluginId, context: ModelContext, code: String) async throws {
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
    
    
    
}

