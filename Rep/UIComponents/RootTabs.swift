import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct RootTabs: View {
    @State private var showImportToast: Bool = false
    @State private var showGeneratedChat: Bool = false
    @StateObject private var importManager = NotionDataManager.shared
    @StateObject private var chatGenerationManager = AIRequestManager.shared
    
    @Binding var isUserAuthed: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView {
                    Tab("Menu", systemImage: "list.bullet") {
                        MainMenu(isUserAuthed: $isUserAuthed, pageID: "pageID")
                    }
                    Tab("Settings", systemImage: "gear") {
                        SettingsView()
                    }
                    Tab("Import", systemImage: "plus.app") {
                        NotionImportPageView()
                    }
                    
                }.tabBarMinimizeBehavior(.never)
                    .background(Color.clear)
                
                    .overlay(alignment: .top) {
                        if showImportToast {                                ///for notion imports
                            withAnimation(.easeInOut(duration: 0.2)) {
                                ToastNotification()
                                    .transition(.move(edge: .top).combined(with: .blurReplace))
                                    .allowsHitTesting(false)
                                    .fixedSize(horizontal: false, vertical: false)
                                    .ignoresSafeArea(edges: .top).padding(.top, 1)
                            }
                        }
                        
                        if showGeneratedChat {                              /// for AI generated notes
                            withAnimation(.easeInOut(duration: 0.2)) {
                                ChatDialogToast()
                                    .transition(.move(edge: .top).combined(with: .blurReplace))
                                    .allowsHitTesting(false)
                                    .fixedSize(horizontal: false, vertical: false)
                                    .ignoresSafeArea(edges: .top).padding(.top, 1)
                            }
                        }
                    }
            }
        }
        
        .task(id: importManager.isPageImportedNotification) {
            Task { @MainActor in
                guard self.importManager.isPageImportedNotification else { return }
                await Toast.shared.callToastOnPageLoad($showImportToast)
            }
        }
        
        .task(id: chatGenerationManager.isNotesGenerated) {
            Task { @MainActor in
                guard self.chatGenerationManager.isNotesGenerated else { return }
                await Toast.shared.callToastOnPageLoad($showGeneratedChat)
            }
        }
    }
}

#Preview {
    RootTabs(isUserAuthed: .constant(true))                                ///liquid glass tab bar
}
