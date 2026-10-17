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
    
    
    func syncCachedPages(context: ModelContext, url: URL? = nil) async throws {
        var obsidianVaultUrl: URL
        var bookmarkDataFile: Data
        
        if let url: URL = url {
            bookmarkDataFile = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkDataFile, forKey: "obsidianVaultBookmark")
            
        } else {
            guard let savedBookmark: Data = UserDefaults.standard.data(forKey: "obsidianVaultBookmark") else { throw ErrorDesc.fileNotAccessible }
            bookmarkDataFile = savedBookmark
        }
        
        var isStale: Bool = false
        let saveUrl: URL = try URL(resolvingBookmarkData: bookmarkDataFile,options: [],relativeTo: nil, bookmarkDataIsStale: &isStale)
        obsidianVaultUrl = saveUrl
        
        let desc: FetchDescriptor<ObsidianPageTitle> = FetchDescriptor<ObsidianPageTitle>()
        let fetch = try? context.fetch(desc)
        
        guard obsidianVaultUrl.startAccessingSecurityScopedResource() else { throw ErrorDesc.fileNotAccessible }
        defer { obsidianVaultUrl.stopAccessingSecurityScopedResource() }
        guard let enumeratedFiles: FileManager.DirectoryEnumerator = FileManager.default.enumerator(at: obsidianVaultUrl, includingPropertiesForKeys: [.isRegularFileKey], options: .skipsHiddenFiles) else { throw ErrorDesc.fileNotAccessible }
        
        while let item = enumeratedFiles.nextObject() {
            guard let fileItem = item as? URL else { throw ErrorDesc.fileNotAccessible }
            let syncedFileContent: String = try String(contentsOf: fileItem, encoding: .utf8)
            //TODO: cache back into swift data schema 
        }
    }
}

