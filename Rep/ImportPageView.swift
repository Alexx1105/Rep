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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissImporTab
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
                PluginListCard().padding(.vertical)
            
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
        .sheet(isPresented: $showOathWebView) {  //TODO: unify oauth view for all providers here
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
