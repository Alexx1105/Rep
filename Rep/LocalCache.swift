//
//  PersistantDB.swift
//  MuscleMemory
//
//  Created by alex haidar on 3/29/25.
//

import Foundation
import SwiftData
import SwiftUI



@Model public class UserEmail {                                     ///email from Oauth flow
    @Attribute(.unique) public var personEmail: String?
    
    public init(personEmail: String?) {
        self.personEmail = personEmail
    }
}

@Model public final class DeletedPage {                                    ///page that is deleted
    @Attribute(.unique) var pageID: String
    var deletedAt: Date = Date()
    init(pageID: String) { self.pageID = pageID }
}

@Model public class UserPageContent {                               ///imported notion body
    @Attribute(.unique) public var id: UUID
    @Attribute public var userContentPage: String?
    @Attribute public var userPageId: String
    @Attribute public var rich_text: String?
    @Attribute public var plain_text: String?
    var isDeleted: Bool = false

    
    public init(userContentPage: String? = nil, userPageId: String, rich_text: String? = nil, plain_text: String? = nil, isDeleted: Bool = false) {
        self.id = UUID()
        self.userContentPage = userContentPage
        self.userPageId = userPageId
        self.rich_text = rich_text
        self.plain_text = plain_text
        self.isDeleted = isDeleted
    }
}

@Model public class UserPageTitle {                             ///tab title + optional emojis
    @Attribute(.unique) var pageID: String
    @Attribute public var text: String
    @Attribute public var emoji: String?
    
    public init(pageID: String, text: String, emoji: String? = nil) {
        self.pageID = pageID
        self.text = text
        self.emoji = emoji
    }
}

@Model public class AuthToken {                                 ///Oauth token
    @Attribute(.unique) public var accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
}

@Model final class NotionPageMetaData {                      ///Notion page metadata schema for on-demand syncing/retrieval feature
    @Attribute(.unique) public var pageID: String
    
    var pageTitle: String
    var lastEditedAt: Date
    var isAutoSync: Bool
    var plain_text: String
    
    init(pageID: String, pageTitle: String, lastEditedAt: Date, isAutoSync: Bool, plain_text: String) {
        self.pageID = pageID
        self.pageTitle = pageTitle
        self.lastEditedAt = lastEditedAt
        self.isAutoSync = isAutoSync
        self.plain_text = plain_text
    }
}

@Model final class SyncUserContentPage {                       
    @Attribute(.unique) var hashed: String

    var content: String
    var pageID: String
    var isDeleted: Bool = false

    init(hashed: String, content: String, pageID: String) {
        self.content = content
        self.pageID = pageID
        self.hashed = hashed
    }
}

@Model final class OpenAIChat {
    @Attribute(.unique) public var openaiId: String
    var content: String
    
    init(content: String, openaiId: String) {
        self.content = content
        self.openaiId = openaiId
    }
}

@Model final class OpenAIMeta {
    @Attribute(.unique) public var id: String
    var model: String
    var status: String
    
    init(id: String, model: String, status: String) {
        self.id = id
        self.model = model
        self.status = status
    }
}

@Model final class RepDesktopTranscription {
    @Attribute(.unique) public var userId: String
    var fullTranscript: String
    var fullNotes: String
    var createdAt: String
    
    init(userId: String, fullTranscript: String, fullNotes: String, createdAt: String) {
        self.userId = userId
        self.fullTranscript = fullTranscript
        self.fullNotes = fullNotes
        self.createdAt = createdAt
    }
}
