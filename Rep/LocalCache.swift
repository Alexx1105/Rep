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
    @Attribute(.unique) var titleID: String
    @Attribute public var icon: String?
    @Attribute public var plain_text: String?
    @Attribute public var emoji: String?
    var isDeleted: Bool = false
    
    public init(titleID: String, icon: String?, plain_text: String?, emoji: String?, isDeleted: Bool = false) {
        self.titleID = titleID
        self.icon = icon
        self.plain_text = plain_text
        self.emoji = emoji
        self.isDeleted = isDeleted
    }
}

@Model public class AuthToken {                                 ///Oauth token
    @Attribute(.unique) public var accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
}




