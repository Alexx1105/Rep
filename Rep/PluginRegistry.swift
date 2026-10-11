//
//  PluginRegistry.swift
//  Rep
//
//  Created by alex haidar on 10/10/26.
/* registry for plugin identity and branding */
import Foundation


final class PluginRegistry {
    static let shared = PluginRegistry()
    
    enum PluginId: String, Codable, Hashable {
        case notion
        case googleDocs
        case obsidian
        case oneNote
    }
    
    struct PluginIdentity: Codable {
        let id: PluginId
        let title: String
        let icon: String
    }
    
    static let pluginProviders: [PluginIdentity] = [
        .init(id: .notion, title: "Notion", icon: "notionLogo"),
        .init(id: .obsidian, title: "Obsidian", icon: "obsidian"),
        .init(id: .googleDocs, title: "Google Docs", icon: "googleDocs"),
        .init(id: .oneNote, title: "Microsoft OneNote", icon: "oneNote")
    ]
    
    func fetchPluginProvider(providerId: PluginId) -> PluginIdentity? {
        return PluginRegistry.pluginProviders.first { $0.id == providerId }
    }
}

