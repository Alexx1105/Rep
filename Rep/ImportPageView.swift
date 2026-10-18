//
//  NotionImportPageView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/26/24.
//
import SwiftUI
import SafariServices
import SwiftData
import UniformTypeIdentifiers


struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}


struct NotionImportPageView: View {
    @ObservedObject private var oauthProvider = OauthProviderManager.shared
    @State private var maskHeight: CGFloat = 0
    @State private var borderOpacity: Double = 1.0
    @State private var showOathWebView: Bool = false
    @State private var authorizationURL: URL?
    @State private var showChatView: Bool = false
    @State var showFilePicker: Bool = false
    @State var fileUrls: [URL] = []
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissImporTab
    @Environment(\.modelContext) private var context
    
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            PluginListCard(onImport: { providerId in
                if providerId == .obsidian {
                    showFilePicker = true
                    return
                }
                
                Task { @MainActor in
                    do {
                        authorizationURL = try await PluginCoordinator.shared.pluginConnectionRedirect(providerId: providerId)
                        showOathWebView = true
                    } catch {
                        print("failed to begin plugin connection", ErrorDesc.pluginError, error)
                    }
                }
            }).padding(.vertical)
            
            VStack(alignment: .center) {
                Button {
                    showChatView = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.clear)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .overlay(RoundedRectangle(cornerRadius: 30).fill(Color.clear).glassEffect(.regular))
                        
                        HStack(spacing: 10) {
                            Image(systemName: "list.bullet.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundStyle(Color.mmDark)
                                .opacity(textOpacity)
                            
                            Text("Generate With AI")
                                .foregroundStyle(Color.mmDark)
                                .opacity(textOpacity)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                            Spacer()
                        }.padding(.horizontal)
                    }
                }.sheet(isPresented: $showChatView) {
                    if showChatView {
                        ChatView()
                            .ignoresSafeArea()
                    }
                }
            }.padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.mmBackground)
        .navigationBarBackButtonHidden()
        .onChange(of: oauthProvider.didReceiveGoogleCallback) { _, didReceiveCallback in
            if didReceiveCallback {
                showOathWebView = false
            }
        }
        .sheet(isPresented: $showOathWebView) {
            if let url = authorizationURL {
                SafariView(url: url)
                    .presentationDetents([.fraction(0.9)])
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showFilePicker) {
            DocPicker(contentType: [UTType(filenameExtension: "md") ?? .plainText], allowMultipleFileSelect: true, asCopy: false) { url in
                fileUrls = url
                showFilePicker = false
                
                Task { @MainActor in
                    do {
                        try await ObsidianDataManager.shared.fetchFirstTimeMarkdownFiles(urls: fileUrls, context: context)   //TODO: Test
                    } catch {
                        print("failed to call obsidian import", ErrorDesc.callsiteError, error)
                    }
                }
            }
        }
    }
}


#Preview {
    NotionImportPageView()
}
