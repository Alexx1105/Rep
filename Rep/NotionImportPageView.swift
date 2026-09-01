//
//  NotionImportPageView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/26/24.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct NotionImportPageView: View {
    
    @State private var maskHeight: CGFloat = 0
    @State private var borderOpacity: Double = 1.0
    @State private var showOathWebView: Bool = false
    @State private var showChatView: Bool = false
    @State private var showAudioTranscriptionView: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissImporTab
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 1) {
            
            Spacer().frame(maxHeight: 180)
            
            HStack {
                Spacer()
                
                Button {
                    showAudioTranscriptionView = true
                } label: {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 25).fill(Color.clear).glassEffect( .regular, in: .rect(cornerRadius: 45))
                            .frame(width: 130, height: 48)
                            .padding(.trailing)
                        
                        HStack(spacing: 8) {
                            
                            Text("Transcribe")
                                .foregroundStyle(Color.mmDark)
                                .opacity(textOpacity)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                            
                            Image(systemName: "microphone.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.mmDark)
                                .opacity(textOpacity)
                            
                        }.padding(.trailing)
                    }
                }
                
            }.frame(maxWidth: .infinity)
            
            Spacer().frame(maxHeight: 5)
            
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: 160)
                    .glassEffect(.regular, in: .rect(cornerRadius: 30))
                    .padding()
                
                
                HStack(alignment: .top) {
                    VStack(spacing: 5 ) {
                        Text("Import notes from your notion")
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                            .opacity(textOpacity)
                            .padding(.top)
                        
                        Text("Grant Notion access to your\naccount to import your notes")
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .opacity(0.50)
                            .padding(.horizontal)
                        Spacer()
                    }.frame(maxHeight: 175)
                    
                    
                }
                
                .padding(.top)
                VStack() {
                    
                    Spacer()
                    ZStack {
                        Button {
                            showOathWebView = true
                        } label: {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.mmDark)
                                .frame(maxWidth: .infinity, maxHeight: 48)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }.padding(.horizontal)
                        
                        HStack(alignment: .center, spacing: 10) {
                            Image("notionLogoReversed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding(.bottom)
                                .opacity(textOpacity)
                            
                            Text("Import page")
                                .foregroundStyle(Color.checkmark)
                                .fontWeight(.medium)
                                .font(.system(size: 16))
                                .padding(.bottom)
                        }
                    }.sheet(isPresented: $showAudioTranscriptionView) {
                        if showAudioTranscriptionView {
                            VoiceTranscriptionView(idempotentKey: UUID())
                        }
                    }
                }.frame(maxHeight: 165)
                    .padding()
            }
            
            VStack(alignment: .center) {
                Button {
                    showChatView = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: 30))
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
        .sheet(isPresented: $showOathWebView) {
            if let url = URL(string: "https://api.notion.com/v1/oauth/authorize?client_id=138d872b-594c-8050-b985-0037723b58e0&response_type=code&owner=user&redirect_uri=https%3A%2F%2Foxgumwqxnghqccazzqvw.supabase.co%2Ffunctions%2Fv1%2Fauth-bridge") {
                SafariView(url: url)
                    .presentationDetents([.fraction(0.9)])
                    .ignoresSafeArea()
            }
        }
    }
}


#Preview {
    NotionImportPageView()
}

