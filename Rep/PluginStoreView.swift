//
//  PluginStoreView.swift
//  Rep
//
//  Created by alex haidar on 10/4/26.
//
import SwiftUI
import Foundation


struct PluginStoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissTab
    
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 95) {
                Button {
                    dismissTab()
                } label: {
                    Image(systemName: "arrow.backward")
                        .foregroundStyle(Color.mmDark.opacity(0.8))
                        .padding(17)
                }
                .glassEffect()
                
                Text("Plugins")
                    .font(.system(size: 20, weight: .bold))
                    .opacity(textOpacity)
                    .padding(.top)
                
                Spacer()
            }
            .padding(.leading)
            
            Divider()
                .frame(maxWidth: .infinity)
            
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        VStack(spacing: 10) {
                            HStack(alignment: .center, spacing: 20) {
                                Image("notionLogo")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .scaledToFit()
                                
                                Image("obsidian")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .scaledToFit()
                                
                                Image("googleDocs")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .scaledToFit()
                            }.padding(.top, 10)
                            
                            Text("Connect your favorite apps and\nimport your notes")
                                .font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        ForEach(0..<3, id: \.self) { index in
                            PluginStoreTab()
                        }.padding(.top)
                        
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 50)
                }
                
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: Color.mmBackground.opacity(1.00), location: 0.00),
                            .init(color: Color.mmBackground.opacity(0.95), location: 0.03),
                            .init(color: Color.mmBackground.opacity(0.83), location: 0.05),
                            
                                .init(color: Color.clear, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                    
                    Spacer()
                    
                    LinearGradient(
                        stops: [
                            .init(color: Color.clear, location: 0.00),
                            .init(color: Color.mmBackground.opacity(0.25), location: 0.55),
                            .init(color: Color.mmBackground.opacity(0.70), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden()
        .background(Color.mmBackground)
    }
}



#Preview {
    PluginStoreView()
}
