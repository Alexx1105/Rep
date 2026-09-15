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
import BackgroundTasks


@MainActor
struct MainMenu: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    
    @Query(sort: [SortDescriptor(\UserPageTitle.pageID)])
    var pageTitles: [UserPageTitle]
    @Query var showUserEmail: [UserEmail]
    @Query var openaiChat: [OpenAIChat]
    @Query var repDesktopTranscriptions: [RepDesktopTranscription]
    @Query var repMobileTranscriptions: [RepMobileTranscription]
    
    @AppStorage("desktop.pollingEnabled") private var isPollingEnabled = false
    
    @Binding var isUserAuthed: Bool
    
    var pageID: String
    
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }

    private var notesTopBlur: some View {
        LinearGradient(
            colors: [
                Color.mmBackground,
                Color.mmBackground.opacity(0.6),
                Color.mmBackground.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 20)
        .allowsHitTesting(false)
    }

    private var notesBottomBlur: some View {
        LinearGradient(
            colors: [
                Color.mmBackground.opacity(0),
                Color.mmBackground.opacity(0.6),
                Color.mmBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 80)
        .allowsHitTesting(false)
    }
    
    @State private var loading = false
    @State private var didLoad = false
    @State private var tabSlideOver = false
    @State private var deleteMultipleTabs = Set<String>()
    @State private var selectedCheckBox = false
    
    @ObservedObject private var AutoSync = SyncController.shared
    
    private func delete(pageID: [String]) async throws {
        let _ = try await supabaseDBClient.from("push_tokens").delete().in("page_id", values: pageID).execute()
        print("page ids here: \(pageID)")
    }
    
    @MainActor
    public class TaskController: ObservableObject {
        private var autoSyncTask: Task<Void, Never>?
        private(set) var isSync: Bool = false
        
        private let pages: ModelContext
        private let context: ModelContext
        
        init(pages: ModelContext, context: ModelContext) {
            self.pages = pages
            self.context = context
        }
        
        
        @MainActor
        func stopAutoSyncTask() {
            autoSyncTask?.cancel()
            autoSyncTask = nil
            
            print("sync task stopped successfully ⏹️")
        }
    }
    
    @State private var taskController: TaskController?
    
    var mainMenuSources: [CombinedDataSource] {
        pageTitles.map{ .notionContent($0)} + openaiChat.map {.openaiChatContent($0)} +
        repDesktopTranscriptions.map { .repDesktopTranscription($0)} + repMobileTranscriptions.map { .repMobileTranscription($0)}
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
                    Text("Notion Workspace Email")
                        .fontWeight(.regular)
                        .font(.system(size: 14))
                        .opacity(textOpacity)
                        .frame(maxWidth: .infinity,maxHeight: 17, alignment: .leading)
                    
                        .onAppear {
                            Task {
                                OAuthTokens.shared.storeModelContext(context)
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
            //Button(action: {debugStartDynamicRepLiveActivity()}) { Rectangle()}   /* for debugging live activity */
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    if AutoSync.isAutoSync {
                        ZStack {
                            Capsule()
                                .frame(minWidth: 110,maxWidth: 180, maxHeight: 21)
                                .glassEffect()
                            
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                    .resizable()
                                    .frame(width: 10, height: 8)
                                    .opacity(textOpacity)
                                
                                Text("Last updated:")
                                    .font(.system(size: 10)).lineSpacing(3)
                                    .fontWeight(.semibold)
                                    .opacity(textOpacity)
                                    .padding(.trailing, 3)
                                
                                let time: Date = LastEdited.shared.lastEdited ?? Date()
                                Text(time.formatted(.dateTime.weekday().day().hour().minute()))
                                    .font(.system(size: 10))
                                    .fontWeight(.regular)
                                    .opacity(textOpacity)
                                
                            }.frame(alignment: .leading)
                        }
                    } else {
                        EmptyView()
                    }
                    Text("Your Notes:")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                        
                }
                Spacer()
                Menu {
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { tabSlideOver = true }
                    } label: {
                        Label("Select tab/s", systemImage: "checkmark.circle")
                    }
                    
                    Button {
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
                            try context.delete(model: UserPageTitle.self, where: #Predicate {deleteTabIDs.contains($0.pageID)})
                            try context.delete(model: UserPageContent.self, where: #Predicate {deleteTabIDs.contains($0.userPageId)})
                            try context.delete(model: OpenAIChat.self, where: #Predicate{deleteTabIDs.contains($0.openaiId)})
                            try context.delete(model: RepDesktopTranscription.self, where: #Predicate {deleteTabIDs.contains($0.userId)})
                            try context.delete(model: RepMobileTranscription.self, where: #Predicate {deleteTabIDs.contains($0.userId)})
                            
                            
                            
                            let fetchDesc = FetchDescriptor<SyncUserContentPage>(predicate: #Predicate {deleteTabIDs.contains($0.pageID)})
                            for i in try context.fetch(fetchDesc) {
                                i.isDeleted = true
                            }
                            
                            for id in deleteTabIDs {
                                let desc = FetchDescriptor<DeletedPage>(
                                    predicate: #Predicate { $0.pageID == id }
                                )
                                
                                if try context.fetch(desc).isEmpty {
                                    context.insert(DeletedPage(pageID: id))
                                }
                            }
                            try context.save()
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
            .frame(maxWidth: .infinity, maxHeight: 95 )
            .padding(.horizontal)
            Spacer()
            
            VStack {
                ZStack {
                    ScrollView {
                        Spacer()
                        ForEach(mainMenuSources, id:\.id) { title in
                            HStack(spacing: 20) {
                                MainMenuDataSourceList(tabSlideOver: $tabSlideOver, deleteMultipleTabs: $deleteMultipleTabs, title: title)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .contentMargins(.top, 20, for: .scrollContent)
                    .contentMargins(.bottom, 80, for: .scrollContent)

                    VStack(spacing: 0) {
                        notesTopBlur
                        Spacer()
                        notesBottomBlur
                    }
                }
                .padding()
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
        
        .task(id: isUserAuthed) {
            guard isUserAuthed else { return }
            await PaymentStore.shared.prepareForAuthenticatedUser()
        }
        
        .onChange(of: AutoSync.isAutoSync) { _, synced in
            guard let controller = taskController else { return }
            
            if synced {
                BackgroundRefresh.shared.startAutoSyncTask(pages: context, context: context)
            } else {
                controller.stopAutoSyncTask()
            }
        }
        
        .onAppear {                      ///init task controller after UI renders
            if taskController == nil {
                taskController = TaskController(pages: context, context: context)
            }
        }
        
        .onAppear {
            Task {
                do {
                    while !Task.isCancelled {
                        guard SyncController.shared.isAutoSync else { return }
                        try await BackgroundRefresh.shared.runSyncWhenReady(context: context, pages: context)
                    }
                } catch {
                    print("sync on app-launch error:", error.localizedDescription)
                }
            }
        }
        
        .onAppear {
            if isPollingEnabled {
                RepDesktopPoller.shared.startPollingNotes(context: context)
            }
        }
    }
}



#Preview {
    MainMenu(isUserAuthed: .constant(true), pageID: "")
        .environment(\.sizeCategory, .large)
    
}
