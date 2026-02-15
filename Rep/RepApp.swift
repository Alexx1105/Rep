//
//  MuscleMemoryApp.swift
//  MuscleMemory
//
//  Created by alex haidar on 4/13/24.
//

import SwiftUI
import AuthenticationServices
import SwiftData



    struct ContainerView: View {
        @StateObject var navigationPath = NavPath.shared

        var body: some View {
            
            NavigationStack(path: $navigationPath.path) {
                LaunchScreen()
               
                    .navigationDestination(for: NavPathItem.self) { navigationPathItem in
                        switch navigationPathItem {
                        case .home:
                            MainMenu(pageID: "")
                        case .settings:
                            SettingsView()
                        case .importPage:
                            NotionImportPageView()
                        case .logOut:
                            SignOutView()
                        case .importpageUser:
                            ImportedNotes(pageID: "")
                        }
                    }
                }
            }
        }


@main
struct MuscleMemoryApp: App {
    
    let centralContainer = try! ModelContainer(for: UserEmail.self, UserPageTitle.self, UserPageContent.self, AuthToken.self, SyncUserContentPage.self, NotionPageMetaData.self)
   
    @AppStorage("appearence.toggle") private var toggleEnabled = false
        
    @StateObject private var paymentStore = PaymentStore()

    var body: some Scene {
        
        WindowGroup {
            RootTabs()
          
                .onOpenURL { url in
                    if let parseCodeQuery = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let codeParse = parseCodeQuery.queryItems?.first(where: {$0.name == "code" })?.value {
                            print("code Query recieved and parsed\(parseCodeQuery)")
                            
                            let context = OAuthTokens.shared.modelContextEmail
    
                            
                            Task {
                                do {
                                    
                                    if SyncController.shared.isAutoSync {
                                        try await bootstrapSync()
                                        
                                    } else {
                                        try await OAuthTokens.shared.exchangeToken(authorizationCode: codeParse, modelContext: context)
                                        try await searchPages.shared.userEndpoint(context: context!)
                                        
                                        let desc = FetchDescriptor<NotionPageMetaData>()
                                        let pageId = try context!.fetch(desc)
                                        
                                        for pg in pageId {
                                            try await ImportUserPage.shared.pageEndpoint(pageID: pg.pageID, context: context!)
                                        }
                                    }
                                } catch {
                                    print("failed async operation(s):\(error)")
                                }
                            }
                            
                            @MainActor
                            func bootstrapSync() async throws {
                                
                                do {
                                    try await OAuthTokens.shared.exchangeToken(authorizationCode: codeParse, modelContext: context)
                                    try await searchPages.shared.userEndpoint(context: context!)
                                    
                                    let desc = FetchDescriptor<NotionPageMetaData>()
                                    let pageId = try context!.fetch(desc)
                                    print("page schemas \(pageId.count)")
                                    for pg in pageId {
                                        try await ImportUserPage.shared.pageEndpoint(pageID: pg.pageID, context: context!)
                                        print("page id: \(pg.pageID)")
                                    }
                                    
                                    print("one time start-up for sync ran 🔄")
                                } catch {
                                    print("one time start-up for sync failed: \(error)")
                                }
                            }
                            
                        } else {
                            print("code query is nil:\(parseCodeQuery)")
                        }
                    }
                }
                .preferredColorScheme(toggleEnabled ? .dark : .light)
        }
        .modelContainer(centralContainer)
        .environmentObject(paymentStore)
        
    }
}

   

#Preview {
    ContainerView()
}
