//
//  combinedDataSources.swift
//  Rep
//
//  Created by alex haidar on 5/16/26.
//for multi data source support for the front end main menu tabs, currently supports notion and openai
import SwiftUI
import SwiftData


enum CombinedDataSource: Identifiable {
    case notionContent(UserPageTitle)
    case openaiChatContent(OpenAIChat)

    var id: String {            //TODO: add support for anthropic, and other data sources
        switch self {
        case .notionContent(let page):
            return "notion-\(page.pageID)"
        case .openaiChatContent(let chat):
            return "openai-\(chat.openaiId)"
        }
    }
}

