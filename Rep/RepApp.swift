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
                    MainMenu(isUserAuthed: $isUserAuthed, pageID: "")
                        .task {
                            if navigationPath.path.isEmpty {
                                navigationPath.path.append(NavPathItem.home)
                            }
                        }
                        .navigationDestination(for: NavPathItem.self) { navigationPathItem in
                            switch navigationPathItem {
                            case .home:
                                MainMenu(isUserAuthed: $isUserAuthed, pageID: "")
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
    
    @StateObject private var paymentStore = PaymentStore.shared
    @StateObject var desktopNotesPoller = RepDesktopPoller.shared
    
    @State private var isPresented: Bool = false
    @State private var isCheckingSession = true
    @State private var notesSettingsRoute: NotesSettingsRoute?
    var body: some Scene {
        
        WindowGroup {
            ZStack {
                if isCheckingSession {
                    ProgressView()
                } else {
                    RootTabs(isUserAuthed: $isUserAuthed)
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
            }
            .task {
                if isUserAuthed {
                    do {
                        _ = try await supabaseDBClient.auth.session
                    } catch {
                        print("Stored sign-in has no Supabase session:", error)
                        isUserAuthed = false
                    }
                }
                isCheckingSession = false
            }
            .onOpenURL { url in
                if let route = NotesSettingsRoute(url: url) {
                    notesSettingsRoute = route
                    return
                }
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
                                    try await NotionDataManager.shared.fetchFirstTimePages(context: context!)
                                }
                            } catch {
                                print("failed async operation(s):", ErrorDesc.concurrencyError, error)
                            }
                        }
                        @MainActor
                        func bootstrapSync(context: ModelContext) async throws {
                            do {
                                try await OAuthTokens.shared.exchangeToken(authorizationCode: codeParse)
                                try await NotionDataManager.shared.fetchFirstTimePages(context: context)
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
            .sheet(item: Binding(
                get: { isUserAuthed && !isCheckingSession ? notesSettingsRoute : nil },
                set: { notesSettingsRoute = $0 }
            )) { route in
                NavigationStack {
                    NotesSettingsDestination(pageID: route.id)
                }
            }
            .preferredColorScheme(toggleEnabled ? .dark : .light)
        }
        .modelContainer(centralContainer)
        .environmentObject(paymentStore)
    }
}

private struct NotesSettingsRoute: Identifiable {
    let id: String

    init?(url: URL) {
        guard url.scheme?.lowercased() == "musclememory.kimchilabs.com",
              url.host == "dynamic-notes", url.path == "/settings",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let pageIDs = components.queryItems?.filter { $0.name == "pageID" } ?? []
        guard pageIDs.count == 1, let pageID = pageIDs.first?.value,
              !pageID.isEmpty else { return nil }
        id = pageID
    }
}

private struct NotesSettingsDestination: View {
    let pageID: String
    @Query private var notionPages: [UserPageTitle]
    @Query private var chats: [OpenAIChat]
    @Query private var desktopNotes: [RepDesktopTranscription]
    @Query private var mobileNotes: [RepMobileTranscription]
    @Environment(\.dismiss) private var dismiss

    private var matchingSources: [CombinedDataSource] {
        notionPages.filter { $0.pageID == pageID }.map { .notionContent($0) }
        + chats.filter { $0.openaiId == pageID }.map { .openaiChatContent($0) }
        + desktopNotes.filter { $0.userId == pageID }.map { .repDesktopTranscription($0) }
        + mobileNotes.filter { $0.userId == pageID }.map { .repMobileTranscription($0) }
    }

    var body: some View {
        if matchingSources.count == 1, let source = matchingSources.first {
            DynamicRepControlsView(pageID: pageID, dataSource: source)
        } else {
            ContentUnavailableView("Notes unavailable", systemImage: "note.text",
                                   description: Text("This note page could not be found on this device."))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}



#Preview {
    ContainerView()
}
