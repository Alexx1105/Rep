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
    
    let centralContainer = try! ModelContainer(for: UserEmail.self, UserPageTitle.self, UserPageContent.self, AuthToken.self)
   
    @AppStorage("appearence.toggle") private var toggleEnabled = false
    @AppStorage("auto.sync") private var isAutoSync: Bool = false
    
    @StateObject private var paymentStore = PaymentStore()

  
    var body: some Scene {
        
        WindowGroup {
            RootTabs()
    
                .onOpenURL { url in
                    if let parseCodeQuery = URLComponents(url: url, resolvingAgainstBaseURL: true ) {
                        if let codeParse = parseCodeQuery.queryItems?.first(where: {$0.name == "code" })?.value {
                            print("code Query recieved and parsed\(parseCodeQuery)")
                            
                            let pages = searchPages.shared.modelContextTitle
                            let context = OAuthTokens.shared.modelContextEmail
                            
                            Task {
                                do {
                                    try await OAuthTokens.shared.exchangeToken(authorizationCode: codeParse, modelContext: context)
                                    try await searchPages.shared.userEndpoint(modelContextTitle: pages, modelContext: context!)
                                    try await ImportUserPage.shared.pageEndpoint(modelContext: context!)
                                    
                                } catch {
                                    print("failed async operation(s):\(error)")
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
