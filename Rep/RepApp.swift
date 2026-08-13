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
    @AppStorage("user.signedIn") private var isUserAuthed: Bool = false
    
    
    var body: some View {
        Group {
            if !isUserAuthed {
                
                AuthView()
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AuthDidSucceed"))) { _ in
                        Task { @MainActor in
                            print("ContainerView: received AuthDidSucceed")
                            isUserAuthed = true
                            print("Auth succeeded; switching to main app and showing MainMenu")
                            navigationPath.path = NavigationPath()
                            navigationPath.path.append(NavPathItem.home)
                        }
                    }
                
            } else {
                NavigationStack(path: $navigationPath.path) {
                    MainMenu(pageID: "")
                        .task {
                            if navigationPath.path.isEmpty {
                                navigationPath.path.append(NavPathItem.home)
                            }
                        }
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
                                ImportedNotes(pageID: "", titleSource:
                                        .openaiChatContent(OpenAIChat(content: "Preview chat content",
                                                                      openaiId: "preview-id")))
                            case .tos:
                                TOSPage()
                            }
                        }
                }
                .id(isUserAuthed)
            }
        }
        .onChange(of: isUserAuthed) { oldValue, newValue in
            if newValue == true {
                Task { @MainActor in
                    print("ContainerView: isUserAuthed changed to true; seeding path -> .home")
                    navigationPath.path = NavigationPath()
                    navigationPath.path.append(NavPathItem.home)
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
    
    
    let centralContainer: ModelContainer = try! ModelContainer(for: UserEmail.self, UserPageTitle.self, UserPageContent.self,
                                                               AuthToken.self, SyncUserContentPage.self, NotionPageMetaData.self,
                                                               DeletedPage.self, OpenAIChat.self, OpenAIMeta.self, RepDesktopTranscription.self,
                                                               RepMobileTranscription.self)
    
    @AppStorage("appearence.toggle") private var toggleEnabled = false
    @AppStorage("user.signedIn") private var isUserAuthed: Bool = false
    
    @StateObject private var paymentStore = PaymentStore()
    @StateObject var desktopNotesPoller = RepDesktopPoller.shared
    
    @State private var isPresented: Bool = false
    var body: some Scene {
        
        WindowGroup {
            ZStack {
                RootTabs()
                    .disabled(!isUserAuthed)
                if !isUserAuthed {
                    AuthView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).ignoresSafeArea())
                        .transition(.opacity)
                        .zIndex(1)
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                }
                PolledDesktopNotesPopover(isPresented: $desktopNotesPoller.didPollerReturnDesktopNotes)
            }
            .onOpenURL { url in
                if let parseCodeQuery = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    if let codeParse = parseCodeQuery.queryItems?.first(where: { $0.name == "code" })?.value {
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

