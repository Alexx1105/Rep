//
//  MuscleMemoryApp.swift
//  MuscleMemory
//
//  Created by alex haidar on 4/13/24.
//

import SwiftUI
import AuthenticationServices
import SwiftData
import BackgroundTasks


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
                    case .tos:
                        TOSPage()
                    }
                }
            }
        }
    }


@main
struct MuscleMemoryApp: App {
    
    init() {
        BackgroundRefresh.bgTaskRegister()
        
        if SyncController.shared.isAutoSync {
            BackgroundRefresh.bgTaskRequest()
        }
    }
    
    let centralContainer = try! ModelContainer(for: UserEmail.self, UserPageTitle.self, UserPageContent.self, AuthToken.self, SyncUserContentPage.self, NotionPageMetaData.self, DeletedPage.self)
    
    @AppStorage("appearence.toggle") private var toggleEnabled = false
    
    @StateObject private var paymentStore = PaymentStore()
    
    var body: some Scene {
        
        WindowGroup {
            RootTabs()
            
                .onOpenURL { url in
                    if let parseCodeQuery = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let codeParse = parseCodeQuery.queryItems?.first(where: {$0.name == "code" })?.value {
                            print("code Query recieved and parsed\(parseCodeQuery)")
                            
                            Task {
                                do {
                                    if SyncController.shared.isAutoSync {
                                        try await bootstrapSync(context: OAuthTokens.shared.modelContext)
                                    } else {
                                        let context = OAuthTokens.shared.modelContext
                                        try await OAuthTokens.shared.exchangeToken(authorizationCode: codeParse)
                                        NotionDataManager.shared.handlePageImported(context: context!)
                                    }
                                } catch {
                                    print("failed async operation(s):", ErrorDesc.concurrencyError, error)
                                }
                            }
                            
                            @MainActor
                            func bootstrapSync(context: ModelContext) async throws {
                                do {
                                    try await OAuthTokens.shared.exchangeToken(authorizationCode: codeParse)
                                    NotionDataManager.shared.handlePageImported(context: context)
                                    
                                    print("one time start-up for sync ran 🔄")
                                } catch {
                                    print("one time start-up for sync failed:", ErrorDesc.syncError, error)
                                }
                            }
                            
                        } else {
                            print("code query is nil:", ErrorDesc.oauthError, parseCodeQuery)
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
