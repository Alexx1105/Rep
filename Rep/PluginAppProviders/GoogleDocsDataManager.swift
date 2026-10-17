//
//  googleDocsDataManager.swift
//  Rep
//
//  Created by alex haidar on 10/11/26.
//
import Foundation
import SwiftData
import Combine
import CryptoKit


@MainActor
public final class GoogleDocsDataManager: ObservableObject {
    @Published public private(set) var isPageImportedNotification: Bool = false
    
    public static let shared: GoogleDocsDataManager = GoogleDocsDataManager()
    private init() {}
    
    
    public func fetchFirstTimePages(pageIDs: [String], context: ModelContext, accessToken: String) async throws {
        self.isPageImportedNotification = false
        guard !pageIDs.isEmpty else { throw ErrorDesc.fileProcessingError }
        var importedPageIDs: Set<String> = []
        for pageID: String in pageIDs {
            try Task.checkCancellation()
            guard importedPageIDs.insert(pageID).inserted else { continue }
            let document: GoogleDocsPageResponse = try await getDocument(pageID: pageID, accessToken: accessToken)
            let formattedString: String = extractFieldsFromBlocks(document)
            try storePage(pageID: document.documentId, pageTitle: document.title, content: formattedString, context: context, isFirstTimeImport: true)
        }
        self.isPageImportedNotification = true
    }
    
    
    public func syncCachedPages(context: ModelContext, accessToken: String) async throws {
        let desc: FetchDescriptor<GooglePageTitle> = FetchDescriptor<GooglePageTitle>()
        let fetchCachedPages: [GooglePageTitle] = try context.fetch(desc)
        let cachedPageIDs: [String] = fetchCachedPages.filter { $0.pageID.hasPrefix("googleDocs:") }.map { String($0.pageID.dropFirst("googleDocs:".count)) }
        for pageID: String in cachedPageIDs {
            try Task.checkCancellation()
            let document: GoogleDocsPageResponse = try await getDocument(pageID: pageID, accessToken: accessToken)
            let formattedString: String = extractFieldsFromBlocks(document)
            try storePage(pageID: document.documentId, pageTitle: document.title, content: formattedString, context: context, isFirstTimeImport: false)
        }
    }
    
    
    public func fetchImportedPageTitles(accessToken: String) async throws -> [GoogleDocsSearchMetaData.Result] {
        guard !accessToken.isEmpty else { throw ErrorDesc.authTokenError }
        var pageIDsImported: [GoogleDocsSearchMetaData.Result] = []
        var nextCursor: String?
        var visitedCursors: Set<String> = []
        
        repeat {
            try Task.checkCancellation()
            guard var searchEndpoint: URLComponents = URLComponents(string: "https://www.googleapis.com/drive/v3/files") else { throw ErrorDesc.invalidUrlError }
            searchEndpoint.queryItems = [
                URLQueryItem(name: "q", value: "mimeType = 'application/vnd.google-apps.document' and trashed = false"),
                URLQueryItem(name: "fields", value: "nextPageToken,incompleteSearch,files(id,name,modifiedTime,webViewLink)"),
                URLQueryItem(name: "pageSize", value: "100"),
                URLQueryItem(name: "supportsAllDrives", value: "true"),
                URLQueryItem(name: "includeItemsFromAllDrives", value: "true")
            ]
            if let cursor: String = nextCursor {
                guard visitedCursors.insert(cursor).inserted else { throw ErrorDesc.paginationError }
                searchEndpoint.queryItems?.append(URLQueryItem(name: "pageToken", value: cursor))
            }
            guard let stringToUrl: URL = searchEndpoint.url else { throw ErrorDesc.invalidUrlError }
            let data: Data = try await fetchPageData(url: stringToUrl, accessToken: accessToken)
            let jsonDecoder: JSONDecoder = makeJSONDecoder()
            let searchResponse: GoogleDocsSearchMetaData = try jsonDecoder.decode(GoogleDocsSearchMetaData.self, from: data)
            guard searchResponse.incompleteSearch != true else { throw ErrorDesc.paginationError }
            pageIDsImported.append(contentsOf: searchResponse.files)
            nextCursor = searchResponse.nextPageToken
        } while nextCursor != nil
        return pageIDsImported
    }
    
    
    public func getDocument(pageID: String, accessToken: String) async throws -> GoogleDocsPageResponse {
        guard !pageID.isEmpty else { throw ErrorDesc.invalidUrlError }
        let pagesEndpoint: URL = URL(string: "https://docs.googleapis.com/v1/documents")!.appendingPathComponent(pageID)
        guard var searchEndpoint: URLComponents = URLComponents(url: pagesEndpoint, resolvingAgainstBaseURL: false) else { throw ErrorDesc.invalidUrlError }
        searchEndpoint.queryItems = [URLQueryItem(name: "includeTabsContent", value: "true")]
        guard let stringToUrl: URL = searchEndpoint.url else { throw ErrorDesc.invalidUrlError }
        let data: Data = try await fetchPageData(url: stringToUrl, accessToken: accessToken)
        let jsonDecoder: JSONDecoder = makeJSONDecoder()
        return try jsonDecoder.decode(GoogleDocsPageResponse.self, from: data)
    }
    
    
    private func fetchPageData(url: URL, accessToken: String) async throws -> Data {
        guard !accessToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        var request: URLRequest = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else { throw ErrorDesc.invalidUrlError }
        guard (200..<300).contains(httpResponse.statusCode) else { throw ErrorDesc.urlResponseError }
        return data
    }
    
    
    private func makeJSONDecoder() -> JSONDecoder {
        let jsonDecoder: JSONDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let c: SingleValueDecodingContainer = try decoder.singleValueContainer()
            let dateString: String = try c.decode(String.self)
            let format: ISO8601DateFormatter = ISO8601DateFormatter()
            format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
            if let date: Date = format.date(from: dateString) { return date }
            format.formatOptions = [.withInternetDateTime]
            if let date: Date = format.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Date string does not match expected format")
        }
        return jsonDecoder
    }
    
    
    private func extractFieldsFromBlocks(_ document: GoogleDocsPageResponse) -> String {
        var extractedFields: [String] = []
        if let tabs: [GoogleDocsPageResponse.Tab] = document.tabs, !tabs.isEmpty {
            extractedFields = extractFieldsFromTabs(tabs)
        } else {
            extractedFields = extractFieldsFromContent(document.body?.content ?? [])
        }
        return extractedFields.joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractFieldsFromTabs(_ tabs: [GoogleDocsPageResponse.Tab]) -> [String] {
        var extractedFields: [String] = []
        for tab: GoogleDocsPageResponse.Tab in tabs {
            extractedFields.append(contentsOf: extractFieldsFromContent(tab.documentTab?.body?.content ?? []))
            extractedFields.append(contentsOf: extractFieldsFromTabs(tab.childTabs ?? []))
        }
        return extractedFields
    }
    
    private func extractFieldsFromContent(_ blocks: [GoogleDocsPageResponse.Block]) -> [String] {
        var extractedFields: [String] = []
        for blockList: GoogleDocsPageResponse.Block in blocks {
            if let paragraph: GoogleDocsPageResponse.Paragraph = blockList.paragraph {
                let joinedContent: String = (paragraph.elements ?? []).map { $0.textRun?.content ?? "" }.joined()
                extractedFields.append(joinedContent)
            }
            if let table: GoogleDocsPageResponse.Table = blockList.table {
                for row: GoogleDocsPageResponse.TableRow in table.tableRows ?? [] {
                    for cell: GoogleDocsPageResponse.Body in row.tableCells ?? [] {
                        extractedFields.append(contentsOf: extractFieldsFromContent(cell.content ?? []))
                    }
                }
            }
            if let contents: GoogleDocsPageResponse.Body = blockList.tableOfContents {
                extractedFields.append(contentsOf: extractFieldsFromContent(contents.content ?? []))
            }
        }
        return extractedFields
    }
    
    
    private func storePage(pageID: String, pageTitle: String, content: String, context: ModelContext, isFirstTimeImport: Bool) throws {
        let pageID: String = "googleDocs:\(pageID)"
        let titleFetch: FetchDescriptor<GooglePageTitle> = FetchDescriptor<GooglePageTitle>(predicate: #Predicate { $0.pageID == pageID })
        let contentFetch: FetchDescriptor<GooglePageContent> = FetchDescriptor<GooglePageContent>(predicate: #Predicate { $0.pageID == pageID })
        let existingTab: GooglePageTitle? = try context.fetch(titleFetch).first
        
        guard isFirstTimeImport || existingTab != nil else { return }
        
        if let title: GooglePageTitle = existingTab {
            title.text = pageTitle
        } else {
            let title: GooglePageTitle = GooglePageTitle(pageID: pageID, text: pageTitle, emoji: nil)
            context.insert(title)
        }
        
        if let contentExists: GooglePageContent = try context.fetch(contentFetch).first {
            contentExists.userContentPage = content
        } else {
            let pageContent: GooglePageContent = GooglePageContent(pageID: pageID, userContentPage: content)
            context.insert(pageContent)
        }
        try context.save()

        Task {
            let chunkedRows: [String] = content.components(separatedBy: "\n• ").flatMap { $0.components(separatedBy: "\n") }
            let token: String = await PushTokenManager.generatePushToken()
            for row: String in chunkedRows {
                let contentHash: String = SHA256.hash(data: Data(row.utf8)).map { String(format: "%02x", $0) }.joined()
                await SupabaseClientManager.shared.supabaseGoogleDocsUpsert(token: token, pageID: pageID, title: pageTitle, content: row, contentHash: contentHash)
            }
        }
    }
}
