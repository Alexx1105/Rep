//
//  NotionDataManager.swift
//  Rep
//
//  Created by alex haidar on 3/16/26.
//
import Foundation
import SwiftData
import AuthenticationServices


@MainActor
public class NotionDataManager: ObservableObject {
    static let shared: NotionDataManager = NotionDataManager(id: "", passEndpoint: "", userPageId: "")
    
    @Published var plain_text: String?
    @Published var emoji: String?
    @Published var id: String
    
    init(id: String, passEndpoint: String, userPageId: String) {
        self.id = id
        self.passEndpoint = passEndpoint
        self.userPageId = userPageId
    }
    
    enum ErrorDesc: LocalizedError {        ///start using this for logging local errors
        case authTokenError
        case urlRequestError
        case parsingError
        case encodeError
        case decodeError
        case paginationError
        case callsiteError
        case persistenceError
    }
    
    @MainActor
    public func fetchAuthToken(context: ModelContext) throws -> String {
        let fetchDescriptor = FetchDescriptor<AuthToken>()
        let authToken = try context.fetch(fetchDescriptor)
        
        guard let token = authToken.first?.accessToken else { throw ErrorDesc.authTokenError }
        return token
    }
    
    let searchEndpoint: URL = URL(string: "https://api.notion.com/v1/search")!
    
    public func getHeaders(context: ModelContext) async throws {
        let passToken = try fetchAuthToken(context: context)
        var urlRequest = URLRequest(url: searchEndpoint)
        
        guard !passToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        urlRequest.addValue("Bearer \(passToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("2026-03-11", forHTTPHeaderField: "Notion-Version")
        
        do {
            urlRequest.httpMethod = "POST"
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
            
            guard let encodeData = String(data: data, encoding: .utf8) else { throw ErrorDesc.encodeError }
            print("data encoded: \(encodeData)")
            
            let decodePageData = JSONDecoder()
            decodePageData.dateDecodingStrategy = .custom { decoder in
                
                let c = try decoder.singleValueContainer()
                let dateString = try c.decode(String.self)
                
                let format = ISO8601DateFormatter()
                format.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
                
                if let date = format.date(from: dateString) { return date }
                
                format.formatOptions = [.withInternetDateTime]
                if let dateTime = format.date(from: dateString) { return dateTime }
                
                throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: c.codingPath,
                                                                                  debugDescription: "Date string does not match expected format"))
            }
            
            let decodePage = try decodePageData.decode(NotionSearchRequest.self, from: data)
            for i in decodePage.results {
                guard let pageID = i.id else { continue }
                
                print("====================================\n Header results: \(i)")
                let properties: NotionSearchRequest.TitleDict? = i.properties?.title
                let emoji: String? = i.icon?.emoji
                let text: String? = properties?.title.first?.plain_text
                print("====================================\n PLAIN TEXT TITLE ✅: \(text ?? "nil")")
                
                let title = UserPageTitle(titleID: pageID, plain_text: text, emoji: emoji)
                context.insert(title)
                
                try await getBlocks(pageID: pageID, context: context)  ///pass pageID to the next function
            }
            
        } catch {
            print("parsing error ❗️: \(ErrorDesc.parsingError)")
        }
    }
    
    
    var passEndpoint: String
    var userContentPage: String?
    var userPageId: String
    var storePageIDSets: Set<String> = []
    var constructedEndpoint: String = ""
    var paginatedRequest: URL?
    
    @Published var mainBlockBody: [MainBlockBody.Block] = []
    
    @MainActor
    public func getBlocks(pageID: String, context: ModelContext) async throws {    ///import acc user's notion page
        
        let pagesEndpoint: String = "https://api.notion.com/v1/blocks/" + "\(pageID)/children"
        constructedEndpoint = pagesEndpoint
        
        guard let stringToUrl: URL = URL(string: constructedEndpoint) else { return }
        var request: URLRequest = URLRequest(url: stringToUrl)
        
        let auth = try fetchAuthToken(context: context)
        guard !auth.isEmpty else { throw ErrorDesc.authTokenError }
        
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.addValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpMethod = "GET"
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ErrorDesc.urlRequestError }
            
            guard let _ : String = String(data: data, encoding: .utf8) else { throw ErrorDesc.encodeError }
            
            let decoder = JSONDecoder()
            let decodeBlocks: MainBlockBody = try decoder.decode(MainBlockBody.self, from: data)
            
            var returnedResults: [MainBlockBody.Block] = decodeBlocks.results
            var hasMore: Bool = decodeBlocks.has_more
            var nextCursor: String? = decodeBlocks.next_cursor
            
            while hasMore, let cursor = nextCursor {
                let paginate: String = pagesEndpoint + "?page_size=100&start_cursor=\(cursor)"
                guard let paginateStringToUrl: URL = URL(string: paginate) else { throw ErrorDesc.paginationError }
                
                paginatedRequest = paginateStringToUrl
                var paginationRequest: URLRequest = URLRequest(url: paginateStringToUrl)
                paginationRequest.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
                paginationRequest.addValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
                paginationRequest.httpMethod = "GET"
                
                let (paginatedData, _) = try await URLSession.shared.data(for: paginationRequest)
                let decodePaginatedData = try JSONDecoder().decode(MainBlockBody.self, from: paginatedData)
                
                returnedResults.append(contentsOf: decodePaginatedData.results)
                hasMore = decodePaginatedData.has_more
                nextCursor = decodePaginatedData.next_cursor
                print("paginated successfully ✅\n====================================")
            }
            
            var returnDecodedResults = returnedResults
            for i in 0..<returnDecodedResults.count {
                var extractedFields: [String] = []
                let blockList = returnDecodedResults[i]
                
                switch blockList.type {
                case "numbered_list_item":
                    if let n = blockList.numbered_list_item?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(n))
                    }
                case "bulleted_list_item":
                    if let b = blockList.bulleted_list_item?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(b))
                    }
                case "heading_1":
                    if let h1 = blockList.heading_1?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(h1))
                    }
                case "heading_2":
                    if let h2 = blockList.heading_2?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(h2))
                    }
                case "heading_3":
                    if let h3 = blockList.heading_3?.rich_text {
                        extractedFields.append(MainBlockBody.joinContent(h3))
                    }
                default: break
                }
                
                if let paragraph = returnDecodedResults[i].paragraph?.rich_text {
                    
                    let joinedContent: String = MainBlockBody.joinContent(paragraph)
                    extractedFields.append(contentsOf: [joinedContent])
                    print("ALL LISTS ✅: \(joinedContent)")
                    
                }
                returnDecodedResults[i].ExtractedFields = extractedFields
            }
            
            await MainActor.run {
                self.mainBlockBody = returnDecodedResults
            }
            
            let formattedString: String = returnDecodedResults.flatMap{ $0.ExtractedFields }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let chunkedRows: [String] = formattedString.components(separatedBy: "\n• ").flatMap {$0.components(separatedBy: "\n")}
            print("formatted & trimmed string ✅: \(chunkedRows)")
            
            do {
                let content = UserPageContent(userContentPage: formattedString, userPageId: pageID)
                context.insert(content)
                try context.save()
            } catch {
                print("Error persisting to CoreData ❗️", ErrorDesc.persistenceError)
            }
            
            
            
        } catch {
            print("error returning page blocks ❗️", ErrorDesc.parsingError)
        }
    }
    
    
//     func mainCaller(context: ModelContext, pageID: String) async throws {
//        do {
//            try await NotionDataManager.shared.getHeaders(context: context)
//            try await NotionDataManager.shared.getBlocks(pageID: pageID, context: context)
//            
//            print("headers and blocks fetched successfully")
//        } catch {
//            print("function call failure ❗️", ErrorDesc.callsiteError)
//        }
//    }
}


