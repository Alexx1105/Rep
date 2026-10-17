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
                            case .pluginStore:
                                PluginStoreView()
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
                                                               RepMobileTranscription.self, ObsidianPageTitle.self, ObsidianPageContent.self,
                                                               GooglePageTitle.self, GooglePageContent.self)
    
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
                do {
                    if let handoffCode: String = try OauthProviderManager.notionHandoffCode(from: url) {
                        Task { @MainActor in
                            do {
                                try await PluginCoordinator.shared.connectPluginProvider(providerId: .notion, context: centralContainer.mainContext, code: handoffCode, fileUrls: nil)
                            } catch {
                                print("failed to complete Notion connection:", ErrorDesc.oauthError, error)
                            }
                        }
                        return
                    }
                } catch {
                    print("invalid Notion callback:", ErrorDesc.oauthError)
                    return
                }
                do {
                    if let handoffCode: String = try OauthProviderManager.googleDocsHandoffCode(from: url) {
                        Task { @MainActor in
                            do {
                                try await PluginCoordinator.shared.connectPluginProvider(providerId: .googleDocs, context: centralContainer.mainContext, code: handoffCode, fileUrls: nil)
                            } catch {
                                print("failed to complete Google connection:", ErrorDesc.oauthError, error)
                            }
                        }
                        return
                    }
                } catch {
                    print("invalid Google callback:", ErrorDesc.oauthError)
                    return
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
        guard pageIDs.count == 1, let pageID = pageIDs.first?.value, !pageID.isEmpty else { return nil }
        id = pageID
    }
}

private struct NotesSettingsDestination: View {
    let pageID: String
    @Query private var notionPages: [UserPageTitle]
    @Query private var chats: [OpenAIChat]
    @Query private var desktopNotes: [RepDesktopTranscription]
    @Query private var mobileNotes: [RepMobileTranscription]
    @Query private var obisidanPages: [ObsidianPageTitle]
    @Query private var googlePages: [GooglePageTitle]
    @Environment(\.dismiss) private var dismiss
    
    private var matchingSources: [CombinedDataSource] {
        notionPages.filter { $0.pageID == pageID }.map { .notionContent($0) }
        + chats.filter { $0.openaiId == pageID }.map { .openaiChatContent($0) }
        + desktopNotes.filter { $0.userId == pageID }.map { .repDesktopTranscription($0) }
        + mobileNotes.filter { $0.userId == pageID }.map { .repMobileTranscription($0) }
        + obisidanPages.filter { $0.pageID == pageID }.map { .obsidianPageTitle($0) }
        + googlePages.filter { $0.pageID == pageID }.map { .googlePageTitle($0) }
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
