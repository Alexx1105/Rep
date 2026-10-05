import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit


struct RootTabs: View {
    @State private var showImportToast: Bool = false
    @State private var showGeneratedChat: Bool = false
    @State private var showAudioTranscriptionView: Bool = false
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0
    @StateObject private var importManager = NotionDataManager.shared
    @StateObject private var chatGenerationManager = AIRequestManager.shared
    @Binding var isUserAuthed: Bool
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    Tab("Menu", systemImage: "list.bullet", value: 0) {
                        MainMenu(isUserAuthed: $isUserAuthed, pageID: "pageID")
                    }
                    Tab("Settings", systemImage: "gear", value: 1) {
                        SettingsView()
                    }
                    Tab("Import", systemImage: "plus.app", value: 2) {
                        NotionImportPageView()
                    }
                    
                    if #available(iOS 27.0, *) {
                        Tab("", systemImage: "waveform.circle.fill", value: 3, role: .prominent) {
                            Color.clear
                        }
                    }
                }
                .tabBarMinimizeBehavior(.never)
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 3 {
                        selectedTab = previousTab
                        showAudioTranscriptionView = true
                    } else {
                        previousTab = newValue
                    }
                }
                .sheet(isPresented: $showAudioTranscriptionView) {
                    VoiceTranscriptionView(idempotentKey: UUID())
                }
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
            .navigationDestination(for: NavPathItem.self) { route in
                if route == .pluginStore {
                    PluginStoreView()
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
    RootTabs(isUserAuthed: .constant(true))
}
