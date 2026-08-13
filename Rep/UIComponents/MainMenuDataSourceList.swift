import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct MainMenuDataSourceList: View {         ///conditionally renders the list in ImportedNotes.swift based on data source. notion, openai etc
    @Environment(\.modelContext) var context
    @Binding var tabSlideOver: Bool
    @Binding var deleteMultipleTabs: Set<String>
    @State private var selectedCheckBox = false
    
    let title: CombinedDataSource
    var body: some View {
        
        switch title {
            
        case .notionContent(let pageTitle):
            if tabSlideOver {
                Button {
                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                    if deleteMultipleTabs.contains(pageTitle.pageID) {
                        deleteMultipleTabs.remove(pageTitle.pageID)
                    } else {
                        deleteMultipleTabs.insert(pageTitle.pageID)
                    }
                    
                } label: {
                    TabSelectionCircle(selectedTab: deleteMultipleTabs.contains(pageTitle.pageID))
                }
            }
            
            if !pageTitle.text.isEmpty {
                NavigationLink {
                    ImportedNotes(pageID: pageTitle.pageID, titleSource: title)
                        .navigationBarBackButtonHidden(true)
                    
                } label: {
                    MainMenuTab(userPageTitle: pageTitle, openaiChatTitle: nil, repDesktopAudioTitle: nil, repMobileAudioTitle: nil,  dataSource: title)
                }
                .allowsHitTesting(!tabSlideOver)
            }
            
        case .openaiChatContent(let chatTitle):
            if tabSlideOver {
                Button {
                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                    if deleteMultipleTabs.contains(chatTitle.openaiId) {
                        deleteMultipleTabs.remove(chatTitle.openaiId)
                    } else {
                        deleteMultipleTabs.insert(chatTitle.openaiId)
                    }
                    
                } label: {
                    TabSelectionCircle(selectedTab: deleteMultipleTabs.contains(chatTitle.openaiId))
                }
            }
            
            if !chatTitle.content.isEmpty {
                NavigationLink {
                    ImportedNotes(pageID: chatTitle.content, titleSource: title)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    MainMenuTab(userPageTitle: nil, openaiChatTitle: chatTitle, repDesktopAudioTitle: nil, repMobileAudioTitle: nil, dataSource: title)
                }.allowsHitTesting(!tabSlideOver)
            }
            
        case .repDesktopTranscription(let desktopAudioTitle):
            if tabSlideOver {
                Button {
                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                    if deleteMultipleTabs.contains(desktopAudioTitle.userId) {
                        deleteMultipleTabs.remove(desktopAudioTitle.userId)
                    } else {
                        deleteMultipleTabs.insert(desktopAudioTitle.userId)
                    }
                    
                } label: {
                    TabSelectionCircle(selectedTab: deleteMultipleTabs.contains(desktopAudioTitle.userId))
                }
            }
            
            if !desktopAudioTitle.fullNotes.isEmpty {
                NavigationLink {
                    ImportedNotes(pageID: desktopAudioTitle.userId, titleSource: title)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    MainMenuTab(userPageTitle: nil, openaiChatTitle: nil, repDesktopAudioTitle: desktopAudioTitle, repMobileAudioTitle: nil, dataSource: title)
                }.allowsHitTesting(!tabSlideOver)
            }
            
        case .repMobileTranscription(let mobileAudioTitle):
            if tabSlideOver {
                Button {
                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                    if deleteMultipleTabs.contains(mobileAudioTitle.userId) {
                        deleteMultipleTabs.remove(mobileAudioTitle.userId)
                    } else {
                        deleteMultipleTabs.insert(mobileAudioTitle.userId)
                    }
                    
                } label: {
                    TabSelectionCircle(selectedTab: deleteMultipleTabs.contains(mobileAudioTitle.userId))
                }
            }
            
            if !mobileAudioTitle.fullNotes.isEmpty {
                NavigationLink {
                    ImportedNotes(pageID: mobileAudioTitle.userId, titleSource: title)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    MainMenuTab(userPageTitle: nil, openaiChatTitle: nil, repDesktopAudioTitle: nil, repMobileAudioTitle: mobileAudioTitle, dataSource: title)
                }.allowsHitTesting(!tabSlideOver)
            }
        }
    }
}

#Preview {
    MainMenuDataSourceList(
        tabSlideOver: .constant(false),
        deleteMultipleTabs: .constant([]),
        title: .notionContent(UserPageTitle(pageID: "", text: "Preview"))
    )
}
