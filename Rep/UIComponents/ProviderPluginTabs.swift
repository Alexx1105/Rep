//
//  ProviderPluginTabs.swift
//  Rep
//
//  Created by alex haidar on 10/4/26.
//
import SwiftUI
import Foundation


struct PluginListTab: View {
    let provider: PluginRegistry.PluginIdentity
    
    var body: some View {
        
        Button {
            
        } label: {
            VStack {
                HStack(spacing: 15) {
                    Image(provider.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text(provider.title)
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.mmDark)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("Import")
                        .font(.system(size: 14)).lineSpacing(1)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.mmDark)
                        .opacity(0.50)
                }
            }
        }
    }
}


struct PluginStoreTab: View {
    let provider: PluginRegistry.PluginIdentity
    
    @ObservedObject private var coordinator = PluginCoordinator.shared
    
    var body: some View {
        
        VStack {
            HStack(spacing: 15) {
                Image(provider.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text(provider.title)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.mmDark)
                    .lineLimit(1)
                
                Spacer()
                
                if coordinator.addedPluginId.contains(provider.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .frame(width: 35, height: 35)
                        .foregroundStyle(Color.green)
                    
                } else {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.prepare()
                        impact.impactOccurred()
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            coordinator.addPluginToList(provider.id)
                        }
                    } label: {
                        
                        ZStack {
                            Circle().frame(width: 35, height: 35)
                                .foregroundStyle(Color.gray).opacity(0.2)
                            
                            Image(systemName: "plus").foregroundStyle(Color.mmDark)
                        }
                    }.transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            Divider()
        }
    }
}



#Preview {
    PluginListTab(provider: PluginRegistry.pluginProviders[2])
}

#Preview {
    PluginStoreTab(provider: PluginRegistry.pluginProviders[0])
}
