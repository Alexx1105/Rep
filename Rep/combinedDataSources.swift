//
//  combinedDataSources.swift
//  Rep
//
//  Created by alex haidar on 5/16/26.
/* For multi data source support for
   the front-end main menu tabs */
import SwiftUI
import SwiftData


enum CombinedDataSource: Identifiable {
    case notionContent(UserPageTitle)
    case openaiChatContent(OpenAIChat)
    case repDesktopTranscription(RepDesktopTranscription)
    case repMobileTranscription(RepMobileTranscription)
    case obsidianPageTitle(ObsidianPageTitle)
    case googlePageTitle(GooglePageTitle)

    
    var id: String {            //TODO: add support for anthropic, and other data sources
        switch self {
        case .notionContent(let page):
            return "notion-\(page.pageID)"
        case .openaiChatContent(let chat):
            return "openai-\(chat.openaiId)"
        case .repDesktopTranscription(let desktopNotes):
            return "desktopNotes-\(desktopNotes.userId)"
        case .repMobileTranscription(let mobileNotes):
            return "mobileNotes-\(mobileNotes.userId)"
        case .obsidianPageTitle(let page):
            return "obsidianPageTitle-\(page.pageID)"
        case .googlePageTitle(let page):
            return "googlePageTitle-\(page.pageID)"
        }
    }
}

