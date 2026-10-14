//
//  ObsidianDataManager.swift
//  Rep
//
//  Created by alex haidar on 10/12/26.
//
import Foundation
import SwiftData


@MainActor
final class ObsidianDataManager: ObservableObject {
    private init() {}
    
    @Published public private(set) var isPageImportedNotification: Bool = false
    static let shared = ObsidianDataManager()
    
    
    func fetchFirstTimeMarkdownFiles(urls: [URL], context: ModelContext) async throws {
        self.isPageImportedNotification = false
        guard !urls.isEmpty else { throw ErrorDesc.invalidUrlError }
        
        for fileUrl in urls {
            let markdownFileContent: String = try String(contentsOf: fileUrl, encoding: .utf8)
            let pageTitle: String = fileUrl.deletingPathExtension().lastPathComponent
            let pageID: String = "obsidian:\(UUID().uuidString)"
            
            let title: ObsidianPageTitle = ObsidianPageTitle(pageID: pageID, text: pageTitle, emoji: nil)
            let content: ObsidianPageContent = ObsidianPageContent( pageID: pageID, userContentPage: markdownFileContent)
            
            context.insert(title)
            context.insert(content)
        }
        try context.save()
        self.isPageImportedNotification = true
    }
    
    //TODO: add sync handler function for obsidian
}

