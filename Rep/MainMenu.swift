//
//  MainMenu.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/21/24.
//

import SwiftUI
import Foundation
import SwiftData
import NotificationCenter
import KimchiKit


@MainActor
struct MainMenu: View {
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query var showUserEmail: [UserEmail]
    @Query var pageTitle: [UserPageTitle]
    
    var pageID: String
    
    var filterTabTitle: [UserPageTitle] {
        pageTitle.filter{($0.titleID == pageID)}
    }

    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @State private var loading = false
    @State private var didLoad = false
    
    @State private var tabSlideOver = false
    @State private var deleteMultipleTabs = Set<String>()
    @State private var selectedCheckBox = false
    

    private func delete(pageID: [String]) async throws {
       
        let _ = try await supabaseDBClient.from("push_tokens").delete().in("page_id", values: pageID).execute()
        print("page ids here: \(pageID)")
   }


    var body: some View {
        
        VStack {
            HStack {
                Rectangle()
                    .cornerRadius(8)
                    .frame(width: 35, height: 35)
                    .opacity(0.25)
                    .padding(.leading)

                
                VStack(spacing: 3) {
                    Text("Workspace email")
                        .fontWeight(.regular)
                        .font(.system(size: 14))
                        .opacity(textOpacity)
                        .frame(maxWidth: .infinity,maxHeight: 17, alignment: .leading)
                    
                        .onAppear {
                            Task {
                                searchPages.shared.modelContextTitleStored(context: modelContext)
                                OAuthTokens.shared.modelContextEmailStored(emailStored: modelContext)
                            }
                        }
                    
                    
                    if let email = showUserEmail.first?.personEmail {
                        Text("\(email)")
                            .fontWeight(.regular)
                            .font(.system(size: 14))
                            .opacity(0.25)
                            .frame(maxWidth: .infinity,maxHeight: 17, alignment: .leading)
                    }
                }
                Spacer()
            }.frame(maxWidth: .infinity, maxHeight: 50)
                .opacity(showUserEmail.first?.personEmail != nil ? 1 : 0)
        
            
            Spacer()
            
            HStack {
                
                //Button(action: {debugStartDynamicRepLiveActivity()}) { Rectangle()}   /* for debugging live activity */
                
                Text("Your notes from Notion:")
                    .fontWeight(.semibold)
                    .opacity(textOpacity)
            
                
                Spacer()
                Menu {
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { tabSlideOver = true }
                    } label: {
                        Label("Select tab/s", systemImage: "checkmark.circle")
                    }; Button {
    
                        deleteMultipleTabs.removeAll()
                        tabSlideOver = false
                        
                    } label: {
                        Label("Cancel select", systemImage: "xmark.circle")
                    }
                      Divider()
                    Button(role: .destructive) {
                        guard !deleteMultipleTabs.isEmpty else { return }
                        let deleteTabIDs = Set(deleteMultipleTabs)
               
                        do {
                            try modelContext.delete(model: UserPageTitle.self, where: #Predicate {deleteTabIDs.contains($0.titleID)})
                            try modelContext.delete(model: UserPageContent.self, where: #Predicate {deleteTabIDs.contains($0.userPageId)})
                            try modelContext.save()
                            
                             let ids = Array(deleteMultipleTabs)
                         
                            print("stored ids: \(deleteMultipleTabs)")
                            Task {
                                try await delete(pageID: ids )
                            }
                            
                            tabSlideOver = false
                            
                            print("deletion successful")
                        } catch {
                            print("tab deletion error: \(error)")
                        }
                      
                    } label: {
                        Label("Delete selected tab/s", systemImage: "trash")
                    }
                } label: {
                    Circle()
                    .frame(height: 45)}
                    .glassEffect()
                    .buttonStyle(PlainButtonStyle())
                    
                    .overlay {
                        Image(systemName: "ellipsis")
                    }
                
            }
            .frame(maxWidth: 370, maxHeight: 100 )
            Spacer()
            
            VStack {
                ScrollView {
                    
                    Spacer()
                    ForEach(pageTitle, id: \.titleID) { isolatedContent in
                        
                        let tabContent = isolatedContent.plain_text ?? ""
                        let tabEmoji = isolatedContent.emoji ?? ""
                        
                        let insertID = isolatedContent.titleID
                        let selectedTab = deleteMultipleTabs.contains(insertID)
                        
                        HStack(spacing: 20) {
                            if tabSlideOver {
                                
                                Button {
                                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                                    if selectedTab { deleteMultipleTabs.remove(insertID)
                                    } else {
                                        deleteMultipleTabs.insert(insertID)
                                    }
                                    
                                } label: {
                                    
                                    TabSelectionCircle(selectedTab: selectedTab)
                                }
                            }
                            
                            if !tabContent.isEmpty || !tabEmoji.isEmpty {
                                NavigationLink {
                                    ImportedNotes(pageID: isolatedContent.titleID)
                                        .navigationBarBackButtonHidden(true)
                                    
                                } label: {
                                    MainMenuTab(emoji: tabEmoji, title: tabContent, pageID: isolatedContent.titleID)
                                }.allowsHitTesting(!tabSlideOver)
                            }
                        }
                    }
                }.padding()
            }
            .foregroundStyle(Color.white.opacity(0.8))
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground)
        .navigationBarBackButtonHidden()
        
        
        .task {
            let pushTokenNotifications = UNUserNotificationCenter.current()
            do {
                try await pushTokenNotifications.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("user could not register: \(error)")
            }
        }
    }
}
    


#Preview {
    MainMenu(pageID: "")
}
