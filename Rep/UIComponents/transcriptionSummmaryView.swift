import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct transcriptionSummmaryView: View {
    @ObservedObject private var audioManager = AudioTranscriptionManager.shared
    @State public var defaultSelectedType: PickerView.PickerType = .notes
    
    
    var body: some View {
        
        ZStack {
            let shape = RoundedRectangle(cornerRadius: 15)
            let fadeHeight: CGFloat = 32
            
            shape.fill(Color.clear).glassEffect(.regular, in: .rect(cornerRadius: 15))
            
            ScrollView {
                VStack(alignment: .leading) {
                    
                    switch defaultSelectedType {
                    case .transcript:
                        Text(audioManager.finishedTranscript)
                            .foregroundStyle(Color.mmDark).opacity(0.5)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .kerning(-0.5)
                            .lineSpacing(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                            .padding(.top)
                            .softReveal(trigger: audioManager.finishedTranscript)
                        
                    case .notes:
                        Text(audioManager.summarizedNotes)
                            .font(.system(size: 14)).lineSpacing(3).fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .padding(.horizontal)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                            .softReveal(trigger: audioManager.summarizedNotes)
                    }
                    
                    Spacer(minLength: 50)
                }.frame(maxWidth: .infinity)
                    .padding(.top, 7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.vertical, fadeHeight)
            }
            
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.mmBackground.opacity(0.95), Color.mmBackground.opacity(0.0)],
                               startPoint: .top, endPoint: .bottom).frame(height: fadeHeight)
                
                Spacer()
                
                LinearGradient(colors: [Color.mmBackground.opacity(0.0), Color.mmBackground.opacity(0.95)],
                               startPoint: .top, endPoint: .bottom).frame(height: fadeHeight)
            }
            .clipShape(shape)
            .allowsHitTesting(false)
            
            VStack(alignment: .center) {
                Spacer(minLength: 20)
                HStack {
                    PickerView(pickerType: $defaultSelectedType)
                    Spacer(minLength: 5)
                    Button {
                        audioManager.isTranscribing = false
                        audioManager.isSummarizing = false
                        audioManager.audioLevels = 0
                        audioManager.didStopAudioStream = false
                        audioManager.finishedTranscript = ""
                        audioManager.liveTranscription = ""
                        audioManager.isTranscriptFinished = false
                    } label: {
                        ZStack {
                            Circle().fill(Color.clear).frame(width: 50, height: 50)
                                .glassEffect(.regular)
                            
                            Image(systemName: "plus").foregroundStyle(Color.mmDark)
                        }
                    }
                }.padding(.bottom)
                    .padding(.bottom)
            }.padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        
        .overlay {
            VStack(alignment: .center) {
                ZStack {
                    Capsule(style: .continuous).fill(Color.clear).glassEffect(.regular)
                        .frame(width: 180, height: 18)
                        
                    
                    Text("Notes auto-save to main menu")
                        .font(.system(size: 10)).fontWeight(.semibold)
                        .foregroundStyle(Color.mmDark)
                }
                Spacer(minLength: 30)
            }.padding(.top)
        }
    }
}

#Preview {
    transcriptionSummmaryView()
}
