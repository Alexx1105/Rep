//
//  ContentView.swift
//  MuscleMemory
//
//  Created by alex haidar on 4/13/24.
//

import SwiftUI
import Foundation
import SwiftData
import OSLog

struct ImportedNotes: View {
    let pageID: String
    
    var filterTitle: [UserPageTitle] {
        pageTitle.filter{($0.pageID) == pageID }
    }
    
    @Environment(\.dismiss) var dismissTab
    @Environment(\.modelContext) var context
    
    @Query var pageTitle: [UserPageTitle]
    
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @State var pageBlocks: [UserPageContent] = []
    let titleSource: CombinedDataSource
    
    private var bottomBlur: some View {
        LinearGradient(gradient: Gradient(colors: [Color.mmBackground.opacity(0),
                                                   Color.mmBackground.opacity(0.6),
                                                   Color.mmBackground]),startPoint: .top, endPoint: .bottom)
        .frame(height: 80)
        .allowsHitTesting(false)
    }
    
    var body: some View {
        NavigationView {
            
            VStack {
                HStack(spacing: 7) {
                    Button {
                        dismissTab()
                    } label: {
                        Image(systemName: "arrow.backward").foregroundStyle(Color.mmDark.opacity(0.8)).padding(17)
                    }.glassEffect()
                    
                    switch titleSource {
                        
                    case (.notionContent(_ )):
                            if let emojis: String? = filterTitle.first?.emoji, let title: String? = filterTitle.first?.text {
                                HStack(spacing: 10) {
                                Text(emojis ?? "")
                                Text(title ?? "")
                                    .fontWeight(.semibold)
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                                
                                Image("notionLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .padding(.trailing)
                                    .opacity(textOpacity)
                            }
                        } else {
                            Rectangle()
                                .cornerRadius(5)
                                .frame(width: 150, height: 20)
                                .opacity(0.1)
                        }
                        
                    case .openaiChatContent(let openaiChatTitle):
                        if !openaiChatTitle.content.isEmpty {
                            
                            Text(openaiChatTitle.content)
                                .fontWeight(.semibold)
                                .truncationMode(.middle)
                                .lineLimit(1)
                            
                            Image("openaiLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .padding(.trailing)
                                .opacity(textOpacity)
                        }
                        
                    case .repDesktopTranscription(let desktopNotes):
                        if !desktopNotes.fullNotes.isEmpty {
                            
                            Text(desktopNotes.fullNotes)
                                .fontWeight(.semibold)
                                .truncationMode(.middle)
                                .lineLimit(1)
                            
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.leading)
                .padding(.top, 5)
                
                Spacer()
                Divider()
                
                ZStack(alignment: .bottom) {
                    switch titleSource {
                        
                    case .notionContent(_ ):
                        if pageBlocks.isEmpty {
                            VStack(spacing: -10) {
                                ForEach(0..<13) { _ in
                                    SkeletonLoader()
                                }
                            }
                        } else {
                            List(pageBlocks, id: \.self) { block in
                                Text(block.userContentPage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                                    .font(.system(size: 16)).lineSpacing(5)
                                    .listRowBackground(Color.mmBackground)
                                    .listRowSeparator(.hidden)
                                    .multilineTextAlignment(.leading)
                                    .padding(.bottom)
                                    .textSelection(.enabled)
                            }
                            .listStyle(.plain)
                        }
                        bottomBlur
                        
                    case .openaiChatContent(let openaiChatContent):
                        let chatLines = openaiChatContent.content.components(separatedBy: .newlines).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        if chatLines.isEmpty {
                            VStack(spacing: -10) {
                                ForEach(0..<13) { _ in
                                    SkeletonLoader()
                                }
                            }
                        } else {
                            ScrollView {
                                ForEach(chatLines, id: \.self) { line in
                                    Text(line)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading)
                                        .font(.system(size: 16)).lineSpacing(3).fontWeight(.medium)
                                        .lineLimit(nil)
                                        .lineHeight(.loose)
                                        .textSelection(.enabled)
                                    
                                }.padding(.bottom)
                            }
                        }
                        bottomBlur
                        
                    case .repDesktopTranscription(let repDesktopTranscription):
                        let transcriptLines = repDesktopTranscription.fullNotes.components(separatedBy: .newlines).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        if transcriptLines.isEmpty {
                            VStack(spacing: -10) {
                                ForEach(0..<13) { _ in
                                    SkeletonLoader()
                                }
                            }
                        } else {
                            ScrollView {
                                ForEach(transcriptLines, id: \.self) { line in
                                    Text(line)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading)
                                        .font(.system(size: 16)).lineSpacing(3).fontWeight(.medium)
                                        .lineLimit(nil)
                                        .lineHeight(.loose)
                                        .textSelection(.enabled)
                                }.padding(.bottom)
                            }
                        }
                        bottomBlur
                    }
                }
                .fontWeight(.medium)
                .ignoresSafeArea(edges: .bottom)
                
            }
            .background(Color.mmBackground)
        }
        .task {
            do {
                pageBlocks = try ImportedNotesFetch.fetchPageContent(context: context, pageID: pageID)
                print("content fetched... \(pageBlocks.count)")
            } catch {
                print("function call failure ❗️:", ErrorDesc.callsiteError, error)
            }
        }
    }
}



#Preview {
    ImportedNotes(pageID: "", titleSource:
            .openaiChatContent(OpenAIChat(content: "Preview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content\nPreview chat content", openaiId: "preview-id")))
}


