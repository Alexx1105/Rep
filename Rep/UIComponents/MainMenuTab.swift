import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct MainMenuTab: View {
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    let userPageTitle: UserPageTitle?
    let openaiChatTitle: OpenAIChat?
    let repDesktopAudioTitle: RepDesktopTranscription?
    let repMobileAudioTitle: RepMobileTranscription?
    
    let dataSource: CombinedDataSource
    
    var body: some View {
        
        ZStack(alignment: .center) {
            Rectangle()
                .fill(.white.opacity(elementOpacityDark))
                .stroke(Color.mmBackground, lineWidth: 0.5)
                .foregroundStyle(Color.mmDark)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDark, lineWidth: 0.3))
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                
                Menu {
                    Text("DynamicRep Settings")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                        .opacity(0.5)
                    
                    NavigationLink(destination: DynamicRepControlsView(pageID: userPageTitle?.pageID ?? "", dataSource: dataSource)) {
                        Label("Live activities", systemImage: "clock.badge")
                    }
                    
                } label: {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(Color.mmDark)
                        .opacity(0.8)
                        .frame(width: 35, height: 35)
                        .padding(5)
                }
                
                HStack(spacing: 10) {
                    if let emoji: String = userPageTitle?.emoji {
                        Text(emoji)
                    }
                    
                    if openaiChatTitle?.content != nil {
                        Image("openaiLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .opacity(textOpacity)
                        
                        Text(openaiChatTitle?.content ?? "OpenAI Chat")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    
                    if userPageTitle?.text != nil {
                        Image("notionLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .opacity(textOpacity)
                        
                        Text(userPageTitle?.text ?? "")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    
                    if repDesktopAudioTitle?.fullNotes != nil {
                        Image(systemName: "waveform.mid").font(.system(size: 25))
                            .foregroundStyle(Color.mmDark)
                        
                        Text(repDesktopAudioTitle?.fullNotes ?? "")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    
                    if repMobileAudioTitle?.fullNotes != nil {
                        Image(systemName: "waveform.mid").font(.system(size: 25))
                            .foregroundStyle(Color.mmDark)
                        
                        Text(repMobileAudioTitle?.fullNotes ?? "")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                }
                
                Spacer()
                Image("arrowChevron")
                    .opacity(0.8)
                    .padding(.trailing)
                
            }
            .padding(.leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 57)
    }
}

#Preview {
    MainMenuTab(
        userPageTitle: UserPageTitle(pageID: "page ID", text: "title", emoji: "😄"),
        openaiChatTitle: OpenAIChat(content: "", openaiId: ""),
        repDesktopAudioTitle: nil,
        repMobileAudioTitle: nil,
        dataSource: .notionContent(UserPageTitle(pageID: "", text: ""))
    )
}
