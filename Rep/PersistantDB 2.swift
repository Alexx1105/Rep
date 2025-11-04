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
    
    public init(userContentPage: String? = nil, userPageId: String, rich_text: String? = nil) {
        self.id = UUID()
        self.userContentPage = userContentPage
        self.userPageId = userPageId
        self.rich_text = rich_text
    }
}

@Model public class UserPageTitle {                             ///tab title + optional emojis
    @Attribute public var titleID: String
    @Attribute public var icon: String?
    @Attribute public var plain_text: String?
    @Attribute public var emoji: String?
    
    public init(titleID: String, icon: String?, plain_text: String?, emoji: String?) {
        self.titleID = titleID
        self.icon = icon
        self.plain_text = plain_text
        self.emoji = emoji
        
    }
}


//@Model public class AuthKeys {                                   //TO-DO: store OAuth key here later
//    @Attribute(.unique) public var oauthPermanentKey: String!
//
//    public init(oauthPermanentKey: String!) {
//        self.oauthPermanentKey = oauthPermanentKey
//    }
//}
//
//


