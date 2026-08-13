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
    
    @State private var selectedTab: TranscriptionSummaryPicker.TrancriptTab = .notes
    @State var pageBlocks: [UserPageContent] = []
    let titleSource: CombinedDataSource
    
    
    private var bottomBlur: some View {
        LinearGradient(gradient: Gradient(colors: [Color.mmBackground.opacity(0),
                                                   Color.mmBackground.opacity(0.6),
                                                   Color.mmBackground]),startPoint: .top, endPoint: .bottom)
        .frame(height: 80)
        .allowsHitTesting(false)
    }
    
    private var topBlur: some View {
        LinearGradient(gradient: Gradient(colors: [Color.mmBackground,
                                                   Color.mmBackground.opacity(0.6),
                                                   Color.mmBackground.opacity(0)]),startPoint: .top, endPoint: .bottom)
        .frame(height: 20)
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
                            
                            Image(systemName: "waveform.mid").foregroundStyle(Color.mmDark)
                            
                        }
                        
                    case .repMobileTranscription(let mobileNotes):
                        
                        if !mobileNotes.fullNotes.isEmpty {
                            
                            Text(mobileNotes.fullNotes)
                                .fontWeight(.semibold)
                                .truncationMode(.middle)
                                .lineLimit(1)
                            
                            Image(systemName: "waveform.mid").foregroundStyle(Color.mmDark)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.leading)
                .padding(.top, 5)
                
                Spacer()
                Divider()
                
                ZStack {
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
                                    .textSelection(.enabled)
                                    .padding(.trailing)
                            }
                            .listStyle(.plain)
                        }
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
                                        .font(.system(size: 16)).lineSpacing(2).fontWeight(.medium)
                                        .lineLimit(nil)
                                        .lineHeight(.loose)
                                        .textSelection(.enabled)
                                        .padding(.trailing)
                                        .padding(.top)
                                }
                                Spacer().frame(height: 30)
                            }
                        }
                    case .repDesktopTranscription(let repDesktopTranscription):
                        let noteLines = repDesktopTranscription.fullNotes.components(separatedBy: .newlines).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        let transcriptLines = repDesktopTranscription.fullTranscript.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty }
                        if transcriptLines.isEmpty || noteLines.isEmpty {
                            VStack(spacing: -10) {
                                ForEach(0..<13) { _ in
                                    SkeletonLoader()
                                }
                            }
                        } else {
                            ScrollView {
                                if selectedTab == .notes {
                                    ForEach(noteLines, id: \.self) { line in
                                        Text(line)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading)
                                            .font(.system(size: 16)).lineSpacing(2).fontWeight(.medium)
                                            .lineLimit(nil)
                                            .lineHeight(.loose)
                                            .textSelection(.enabled)
                                            .padding(.trailing)
                                            .padding(.top)
                                    }
                                    Spacer().frame(height: 50)
                                }
                                
                                if selectedTab == .transcript {
                                    ForEach(transcriptLines, id: \.self) { line in
                                        Text(line)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading)
                                            .font(.system(size: 16)).lineSpacing(1).fontWeight(.regular).fontDesign(.monospaced)
                                            .lineLimit(nil)
                                            .lineHeight(.loose)
                                            .textSelection(.enabled)
                                            .padding(.trailing)
                                            .padding(.top)
                                            .opacity(0.5)
                                    }
                                    Spacer().frame(height: 50)
                                }
                            }
                        }
                    case .repMobileTranscription(let repMobileTranscription):
                        let noteLines = repMobileTranscription.fullNotes.components(separatedBy: .newlines).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        let transcriptLines = repMobileTranscription.fullTranscript.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty }
                        if noteLines.isEmpty || transcriptLines.isEmpty {
                            VStack(spacing: -10) {
                                ForEach(0..<13) { _ in
                                    SkeletonLoader()
                                }
                            }
                        } else {
                            ScrollView {
                                if selectedTab == .notes {
                                    ForEach(noteLines, id: \.self) { line in
                                        Text(line)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading)
                                            .font(.system(size: 16)).lineSpacing(2).fontWeight(.medium)
                                            .lineLimit(nil)
                                            .lineHeight(.loose)
                                            .textSelection(.enabled)
                                            .padding(.trailing)
                                            .padding(.top)
                                    }
                                    Spacer().frame(height: 50)
                                }
                                
                                if selectedTab == .transcript {
                                    ForEach(transcriptLines, id: \.self) { line in
                                        Text(line)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading)
                                            .font(.system(size: 16)).lineSpacing(1).fontWeight(.regular).fontDesign(.monospaced)
                                            .lineLimit(nil)
                                            .lineHeight(.loose)
                                            .textSelection(.enabled)
                                            .padding(.trailing)
                                            .padding(.top)
                                            .opacity(0.5)
                                    }
                                    Spacer().frame(height: 50)
                                }
                            }
                        }
                    }
                    
                    VStack {
                        topBlur
                        Spacer()
                        bottomBlur
                    }
                    
                    if titleSource.isRepTranscription {
                        VStack {
                            Spacer(minLength: 50)
                            TranscriptionSummaryPicker(transcriptTab: $selectedTab)
                            Spacer().frame(height: 25)
                        }
                    }
                }
                .fontWeight(.medium)
                .ignoresSafeArea(edges: .bottom)
            }
            .background(Color.mmBackground)
        }
        .task {
            guard case .notionContent(_) = titleSource else { return }
            
            do {
                pageBlocks = try ImportedNotesFetch.fetchPageContent(context: context, pageID: pageID)
                print("content fetched... \(pageBlocks.count)")
            } catch {
                print("function call failure ❗️:", ErrorDesc.callsiteError, error)
            }
        }
    }
}


extension CombinedDataSource {
    var isRepTranscription: Bool {
        switch self {
        case .repMobileTranscription, .repDesktopTranscription:
            return true
        default:
            return false
        }
    }
}


#Preview("Rep Mobile") {
    ImportedNotes(
        pageID: "preview-id",
        titleSource: .repMobileTranscription(
            RepMobileTranscription(
                userId: "preview-id",
                fullNotes: """
                Rep turns dense notes into lightweight memory loops that are easy to revisit throughout the day. This preview text is intentionally long so the imported notes screen can be tested with realistic wrapping, scrolling, spacing, and selection behavior. A good note view should handle full paragraphs gracefully, keep line height comfortable, avoid clipping long sentences, and still feel readable when the content stretches across multiple screens.
                
                Mobile transcription notes often begin as a loose stream of spoken thoughts: a meeting recap, a lecture explanation, a study session, or a quick voice memo captured while walking between tasks. The note view should make that raw material feel calm and readable once Rep turns it into structured review content.
                
                Use this sample to check how the header truncates, how the body text flows, and whether the bottom blur, padding, and scroll behavior still feel smooth with a larger block of study material. It should also reveal whether long paragraphs feel too dense, whether line spacing gives the eye enough room, and whether the scrolling area feels natural on smaller devices.
                
                A good transcription view should preserve the useful parts of spoken context without making the user feel buried in text. It should support quick scanning, comfortable reading, and enough visual rhythm that users can revisit their notes later without needing to reconstruct the whole conversation from memory.
                
                This final paragraph exists to push the preview closer to a real full-screen note. It should help test the lower edge of the layout, the safe-area behavior, and whether selected text, trailing padding, and the blur overlay still behave correctly when the content extends beyond the first screen.
                """,
                title: "Mobile transcription preview",
                fullTranscript: """
                Speaker 1: This is a preview transcript captured from the desktop helper. The speaker is reviewing a long meeting recap, calling out decisions, follow-up tasks, and a handful of study-worthy details that should become durable notes inside Rep.

                Speaker 1: The meeting started with a quick recap of what we shipped last week, then moved into the parts of the experience that still feel a little rough. The main focus was the imported notes screen, especially how transcription content should behave when the user switches between a clean summary and the raw transcript.

                Speaker 2: One thing we noticed is that desktop recordings tend to be much longer than mobile recordings. A user might capture a lecture, a team call, a tutoring session, or a long study review, so the transcript view needs to handle a lot of text without feeling cramped or broken.

                Speaker 1: The summary view should feel polished and easy to scan, but the transcript view has a different job. It needs to preserve the original wording, including repeated phrases, partial thoughts, and the natural rhythm of someone speaking out loud. That makes spacing, line height, and bottom padding really important.

                Speaker 2: We also talked about the tab picker. It should stay visually present over the content, but the content still needs to scroll underneath it. The final transcript lines should be able to move above the picker so nothing important gets hidden behind the overlay or the bottom blur.

                Speaker 1: Another detail is that raw transcripts can include multiple speakers, timestamps, corrections, and ideas that do not become useful until later. The preview should be long enough to reveal whether the monospaced style feels readable across a full screen of content.

                Speaker 2: If the text is too faint, the transcript feels disabled. If it is too strong, it competes with the summary view. The goal is for it to feel like source material: readable, selectable, and honest about being raw, but still comfortable enough to scan.

                Speaker 1: We should also test how the header behaves while this content is on screen. Long imported transcription titles can come from the first few words of the note, and those titles may be awkward or dense. The layout should truncate gracefully without pushing the waveform icon or back button into strange positions.

                Speaker 2: The bottom of the screen is the most important stress test here. When the transcript is long, the user should be able to scroll all the way to the end and still read the final paragraph clearly. The picker can float above the content, but the scroll view needs enough extra height at the bottom.

                Speaker 1: This final section exists mostly to make the preview feel like a real desktop transcript instead of a tiny placeholder. It should create enough vertical content to test scrolling, text selection, line wrapping, opacity, safe-area behavior, the bottom blur, and the selected tab state inside the preview canvas.

                Speaker 2: After reviewing the preview, the next step would be to tune the bottom spacer, adjust the transcript opacity if needed, and make sure switching between Notes and Transcript does not cause the layout to jump in a distracting way.
                """,
            )
        )
    )
}

#Preview("Rep Desktop") {
    ImportedNotes(
        pageID: "preview-desktop-id",
        titleSource: .repDesktopTranscription(
            RepDesktopTranscription(
                userId: "preview-desktop-id",
                fullTranscript: """
                Speaker 1: This is a preview transcript captured from the desktop helper. The speaker is reviewing a long meeting recap, calling out decisions, follow-up tasks, and a handful of study-worthy details that should become durable notes inside Rep.

                Speaker 1: The meeting started with a quick recap of what we shipped last week, then moved into the parts of the experience that still feel a little rough. The main focus was the imported notes screen, especially how transcription content should behave when the user switches between a clean summary and the raw transcript.

                Speaker 2: One thing we noticed is that desktop recordings tend to be much longer than mobile recordings. A user might capture a lecture, a team call, a tutoring session, or a long study review, so the transcript view needs to handle a lot of text without feeling cramped or broken.

                Speaker 1: The summary view should feel polished and easy to scan, but the transcript view has a different job. It needs to preserve the original wording, including repeated phrases, partial thoughts, and the natural rhythm of someone speaking out loud. That makes spacing, line height, and bottom padding really important.

                Speaker 2: We also talked about the tab picker. It should stay visually present over the content, but the content still needs to scroll underneath it. The final transcript lines should be able to move above the picker so nothing important gets hidden behind the overlay or the bottom blur.

                Speaker 1: Another detail is that raw transcripts can include multiple speakers, timestamps, corrections, and ideas that do not become useful until later. The preview should be long enough to reveal whether the monospaced style feels readable across a full screen of content.

                Speaker 2: If the text is too faint, the transcript feels disabled. If it is too strong, it competes with the summary view. The goal is for it to feel like source material: readable, selectable, and honest about being raw, but still comfortable enough to scan.

                Speaker 1: We should also test how the header behaves while this content is on screen. Long imported transcription titles can come from the first few words of the note, and those titles may be awkward or dense. The layout should truncate gracefully without pushing the waveform icon or back button into strange positions.

                Speaker 2: The bottom of the screen is the most important stress test here. When the transcript is long, the user should be able to scroll all the way to the end and still read the final paragraph clearly. The picker can float above the content, but the scroll view needs enough extra height at the bottom.

                Speaker 1: This final section exists mostly to make the preview feel like a real desktop transcript instead of a tiny placeholder. It should create enough vertical content to test scrolling, text selection, line wrapping, opacity, safe-area behavior, the bottom blur, and the selected tab state inside the preview canvas.

                Speaker 2: After reviewing the preview, the next step would be to tune the bottom spacer, adjust the transcript opacity if needed, and make sure switching between Notes and Transcript does not cause the layout to jump in a distracting way.
                """,
                fullNotes: """
                Desktop helper notes arrive from meetings, lectures, and study sessions recorded on the Mac. This preview checks how imported desktop transcription content appears once it is cached locally and opened from the main notes list. A good desktop note should feel like a clean bridge between the longer conversation and the smaller pieces the user actually wants to review later.
                
                Meeting summaries can contain decisions, action items, definitions, open questions, and context that only makes sense when it stays attached to the original discussion. This preview text is intentionally long enough to test wrapping, scrolling, selection, spacing, and the way the header behaves when the title comes from a real transcription payload.
                
                Use this sample to make sure desktop-imported notes do not feel cramped or visually heavier than mobile recordings. The note body should wrap cleanly, preserve readable spacing, and make long meeting summaries feel easy to scan even when the content includes multiple paragraphs of related information.
                
                The desktop helper flow should feel especially calm because these notes may come from longer sessions: team calls, lectures, interviews, or study reviews. The UI should let the user move through the imported material without losing their place or fighting the scroll view.
                
                This final paragraph pushes the preview closer to a full-screen desktop transcription. It should help test safe-area behavior, trailing padding, bottom blur coverage, and whether the content still looks polished when the text extends below the first visible screen.
                """,
                createdAt: "2026-08-11T20:00:00Z"
            )
        )
    )
}

#Preview("OpenAI Chat") {
    ImportedNotes(
        pageID: "preview-openai-id",
        titleSource: .openaiChatContent(
            OpenAIChat(
                content: """
                This is a preview of imported OpenAI chat content. It should behave like a normal imported note source, with each line or paragraph flowing clearly inside the reading view. Generated answers can be dense, so this preview checks how the screen handles longer explanations without making the content feel boxed in or visually noisy.
                
                OpenAI imports may include study guides, summaries, brainstorms, debugging notes, or structured explanations copied from a chat. The UI should support all of those shapes while keeping the reading experience consistent with Notion, desktop transcription, and mobile transcription sources.
                
                Use this sample to inspect line wrapping, paragraph spacing, scroll behavior, text selection, and the way long answers interact with the bottom blur. The layout should remain stable with larger generated answers, study explanations, summaries, and structured notes that stretch well beyond the first screen.
                
                A good imported chat view should preserve the flow of the original answer while still making it feel native to Rep. Users should be able to skim the content quickly, reread a dense section, and pull useful ideas back into memory without the interface getting in the way.
                
                This final paragraph exists to make the OpenAI preview closer to a realistic long response. It should help reveal whether the header truncates gracefully, whether the body has enough breathing room, and whether the view still feels balanced when the imported content becomes a full note rather than a tiny sample.
                """,
                openaiId: "preview-openai-id"
            )
        )
    )
}

#Preview("Notion") {
    ImportedNotes(
        pageID: "preview-notion-id",
        titleSource: .notionContent(
            UserPageTitle(
                pageID: "preview-notion-id",
                text: "Preview Notion Page With Long Imported Study Notes",
                emoji: "🧠"
            )
        )
    )
}


