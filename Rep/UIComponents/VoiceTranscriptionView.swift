import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

public struct VoiceTranscriptionView: View {
    @Environment(\.dismiss) var closeAudioTranscriptionSheet
    @Environment(\.modelContext) private var context
    
    @State private var streamingText: String = ""
    @State private var dynamicBoxHieght: CGFloat = 0
    @State private var isSummarizing: Bool = false
    @State var transcriptionStartedAt: Date
    @State var isMoreCreditsNeeded: Bool = true
    
    private var transcriptionPlaceholder: String = "Transcript will turn into Live Activity\n powered review notes."
    private var transcriptNotesGenerating: String = "Generating notes... "
    
    public init(transcriptionStartedAt: Date = Date()) {
        self.transcriptionStartedAt = transcriptionStartedAt
    }
    
    private var transcriptionBoxHeight: CGFloat {
        let verticalPadding: CGFloat = 50
        let minHeight: CGFloat = 50
        let maxHeight: CGFloat = 250
        
        guard !audioManager.liveTranscription.isEmpty else { return minHeight }
        return min(max(dynamicBoxHieght, verticalPadding + minHeight), maxHeight)
    }
    
    
    private struct HeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    
    struct TranscriptionView: View {
        @State private var isCaretVisible = true
        let transcription: String
        
        var transcriptionText: Text {
            Text("\(transcription)\(Text(isCaretVisible ? "|" : " ").foregroundColor(.intervalBlue))")
        }
        
        var body: some View {
            transcriptionText
                .foregroundStyle(Color.mmDark)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .kerning(-0.5)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding(.top)
                .background {
                    GeometryReader { geo in
                        Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
                    }
                }
        }
    }
    
    
    @ObservedObject private var audioManager = AudioTranscriptionManager.shared
    @State private var showMacDirections: Bool = false
    
    let transcriptionLiveActivity = LocalLiveActivityManager.shared
    
    public var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    Button {
                        withAnimation { closeAudioTranscriptionSheet() }
                    } label: {
                        ZStack {
                            Circle().fill(Color.clear).glassEffect(.regular)
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.mmDark)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        showMacDirections = true
                    } label: {
                        ZStack {
                            Circle().fill(Color.clear).glassEffect(.regular)
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "macbook.and.iphone")
                                .foregroundStyle(Color.mmDark)
                                .font(.system(size: 20))
                        }
                    }.padding(.trailing)
                        .sheet(isPresented: $showMacDirections) {
                            VStack {
                                MacHelperDirections()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.mmBackground)
                            .presentationDetents([.fraction(0.5)])
                        }
                    
                }.frame(maxWidth: .infinity)
                    .padding(.leading)
                    .padding(.top)
                
                VStack {
                    let shape = RoundedRectangle(cornerRadius: 15)
                    if audioManager.didStopAudioStream && !audioManager.finishedTranscript.isEmpty {
                        EmptyView()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).fill(Color.clear).glassEffect(.regular, in: .rect(cornerRadius: 15))
                            
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        
                                        
                                        HStack {
                                            if audioManager.isSummarizing {
                                                ShimmerText(text: transcriptNotesGenerating).padding(.top)
                                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                                Spacer(minLength: 30)
                                                
                                            } else if !audioManager.isTranscribing {
                                                Text(transcriptionPlaceholder).padding(.top, 10)
                                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                            }
                                            Spacer(minLength: 30)
                                        }
                                        
                                        
                                        if audioManager.isTranscribing {
                                            TranscriptionView(transcription: audioManager.liveTranscription)
                                                .animation(.easeOut(duration: 0.10), value: audioManager.liveTranscription)
                                            Spacer(minLength: 10)
                                            
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .onChange(of: audioManager.liveTranscription) { _,_ in
                                        proxy.scrollTo("typing-caret", anchor: .bottom)
                                    }
                                    
                                    Color.clear.frame(height: 1).id("typing-caret")
                                    
                                }.scrollDisabled(audioManager.liveTranscription.isEmpty)
                            }
                            
                            
                            LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.02),
                                                                      .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                                      .init(color: Color.mmBackground.opacity(0.50), location: 0.05),
                                                                      .init(color: Color.mmBackground.opacity(0.30), location: 0.10),]), startPoint: .top, endPoint: .bottom)
                            .frame(maxWidth: .infinity, maxHeight: transcriptionBoxHeight).clipShape(shape)
                            .allowsHitTesting(false)
                            
                            
                            LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.00),
                                                                      .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                                      .init(color: Color.mmBackground.opacity(0.50), location: 0.10),
                                                                      .init(color: Color.mmBackground.opacity(0.30), location: 0.15),]), startPoint: .bottom, endPoint: .top)
                            .frame(maxWidth: .infinity, maxHeight: transcriptionBoxHeight).clipShape(shape)
                            .allowsHitTesting(false)
                            
                        }.frame(minHeight: 50, maxHeight: transcriptionBoxHeight)
                            .onPreferenceChange(HeightPreferenceKey.self) { height in
                                dynamicBoxHieght = height
                            }
                            .animation(.easeOut(duration: 0.5), value: transcriptionBoxHeight)
                            .padding(.horizontal)
                        Spacer(minLength: 15)
                    }
                    
                    if audioManager.isTranscribing {
                        EmptyView()
                    }
                    
                    if audioManager.didStopAudioStream && !audioManager.finishedTranscript.isEmpty {
                        EmptyView()
                        
                    } else {
                        HStack(spacing: 3) {
                            ForEach(0..<5) { wave in
                                Capsule().frame(width: 40, height: AudioTranscriptionHelper.waveHeight(for: wave, audioLevel: audioManager.audioLevels))
                                    .foregroundStyle(Color.mmDark)
                                    .animation(.spring(response: 0.18, dampingFraction: 0.72), value: audioManager.audioLevels)
                            }
                        }.padding()
                        
                        
                        Button {
                            audioManager.isTranscribing.toggle()
                            
                            Task {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.prepare()
                                impact.impactOccurred()
                                
                                if audioManager.isTranscribing {
                                    try await allowAudioInputAV()
                                    let session = try await audioManager.openAudioSession()
                                    try await audioManager.startAudioStream(session: session)
                                } else {
                                    try await audioManager.stopAudioStream(context: context) { delta in
                                        streamingText += delta
                                    }
                                    audioManager.liveTranscription.removeAll()
                                    
                                }
                            }
                            
                        } label: {
                            ZStack {
                                Circle().fill(Color.clear).glassEffect(.regular)
                                    .frame(maxWidth: 80, maxHeight: 80)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.78), value: audioManager.isTranscribing)
                                
                                if audioManager.isTranscribing {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.red).frame(maxWidth: 45, maxHeight: 45)
                                        .animation(.spring(response: 0.8, dampingFraction: 0.78), value: audioManager.isTranscribing)
                                    
                                        .task {
                                            transcriptionLiveActivity.startLiveActivity(transcriptionStartedAt)
                                        }
                                    
                                        .onChange(of: audioManager.audioLevels) { _,_ in
                                            transcriptionLiveActivity.pushLiveActivity(transcriptionStartedAt)
                                        }
                                    
                                } else {
                                    Circle().fill(Color.red).frame(maxWidth: 70, maxHeight: 70)
                                        .task {
                                            transcriptionLiveActivity.stopLiveActivity()
                                        }
                                }
                            }
                        }.padding(.top)
                            .padding(.bottom)
                    }
                    
                }.padding(.top)
                    .frame(maxHeight: .infinity)
                
            }.background(Color.mmBackground)
            
            if audioManager.isTranscriptFinished {
                transcriptionSummmaryView().ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    .zIndex(10)
                
                    .task {
                        transcriptionLiveActivity.stopLiveActivity()
                    }
            }
            UpgradePlanAlertSheet(isPresented: $isMoreCreditsNeeded, onDismiss: { closeAudioTranscriptionSheet() })
        }.animation(.smooth(duration: 0.45), value: audioManager.isTranscriptFinished)
    }
}

#Preview {
    VoiceTranscriptionView(transcriptionStartedAt: Date())
}
