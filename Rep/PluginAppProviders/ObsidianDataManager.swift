//
//  ObsidianDataManager.swift
//  Rep
//
//  Created by alex haidar on 10/12/26.
//
import Foundation
import SwiftData
import CryptoKit


@MainActor
final class ObsidianDataManager: ObservableObject {
    private init() {}
    
    @Published public private(set) var isPageImportedNotification: Bool = false
    static let shared = ObsidianDataManager()
    
    
    func fetchFirstTimeMarkdownFiles(urls: [URL], context: ModelContext) async throws {
        self.isPageImportedNotification = false
        guard !urls.isEmpty else { throw ErrorDesc.invalidUrlError }
        
        for fileUrl in urls {
            try Task.checkCancellation()
            let isAccessing: Bool = fileUrl.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    fileUrl.stopAccessingSecurityScopedResource()
                }
            }
            let markdownFileContent: String = try String(contentsOf: fileUrl, encoding: .utf8)
            let pageTitle: String = fileUrl.deletingPathExtension().lastPathComponent
            let pageID: String = "obsidian:\(UUID().uuidString)"
            
            let title: ObsidianPageTitle = ObsidianPageTitle(pageID: pageID, text: pageTitle, emoji: nil)
            let content: ObsidianPageContent = ObsidianPageContent( pageID: pageID, userContentPage: markdownFileContent)
            content.fileUrlBookmark = try fileUrl.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            context.insert(title)
            context.insert(content)

            Task {
                let chunkedRows: [String] = markdownFileContent.components(separatedBy: "\n• ").flatMap { $0.components(separatedBy: "\n") }
                let token: String = await PushTokenManager.generatePushToken()
                for row: String in chunkedRows {
                    let contentHash: String = SHA256.hash(data: Data(row.utf8)).map { String(format: "%02x", $0) }.joined()
                    await SupabaseClientManager.shared.supabaseObsidianUpsert(token: token, pageID: pageID, title: pageTitle, content: row, contentHash: contentHash)
                }
            }
        }
        try context.save()
        self.isPageImportedNotification = true
    }
    
    
    func syncCachedPages(context: ModelContext) async throws {
        let desc: FetchDescriptor<ObsidianPageContent> = FetchDescriptor<ObsidianPageContent>()
        let cachedPages: [ObsidianPageContent] = try context.fetch(desc)
        
        for syncContent: ObsidianPageContent in cachedPages {
            try Task.checkCancellation()
            guard let bookmarkDataFile: Data = syncContent.fileUrlBookmark else { continue }
            
            var isStale: Bool = false
            let fileUrl: URL = try URL(resolvingBookmarkData: bookmarkDataFile, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            let isAccessing: Bool = fileUrl.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    fileUrl.stopAccessingSecurityScopedResource()
                }
            }
            
            let syncedFileContent: String = try String(contentsOf: fileUrl, encoding: .utf8)
            syncContent.userContentPage = syncedFileContent
            
            if isStale {
                syncContent.fileUrlBookmark = try fileUrl.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            }

            let pageID: String = syncContent.pageID
            let titleFetch: FetchDescriptor<ObsidianPageTitle> = FetchDescriptor<ObsidianPageTitle>(predicate: #Predicate { $0.pageID == pageID })
            if let title: ObsidianPageTitle = try context.fetch(titleFetch).first {
                let pageTitle: String = title.text
                Task {
                    let chunkedRows: [String] = syncedFileContent.components(separatedBy: "\n• ").flatMap { $0.components(separatedBy: "\n") }
                    let token: String = await PushTokenManager.generatePushToken()
                    for row: String in chunkedRows {
                        let contentHash: String = SHA256.hash(data: Data(row.utf8)).map { String(format: "%02x", $0) }.joined()
                        await SupabaseClientManager.shared.supabaseObsidianUpsert(token: token, pageID: pageID, title: pageTitle, content: row, contentHash: contentHash)
                    }
                }
            }
        }
        try context.save()
    }
}

