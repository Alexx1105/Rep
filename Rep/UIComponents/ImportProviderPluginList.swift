//
//  ImportProviderPluginList.swift
//  Rep
//
//  Created by alex haidar on 10/4/26.
//
import SwiftUI
import Foundation


struct PluginListCard: View {
    @ObservedObject private var coordinator = PluginCoordinator.shared
    
    var body: some View {
        VStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 35) {
                        ForEach(PluginRegistry.pluginProviders.filter { coordinator.addedPluginId.contains($0.id) }, id: \.id) { providerTitle in
                            PluginListTab(provider: providerTitle)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 110)
                    .padding(.bottom, 50)
                }
                
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: Color.mmBackground.opacity(1.00), location: 0.00),
                            .init(color: Color.mmBackground.opacity(0.97), location: 0.30),
                            .init(color: Color.mmBackground.opacity(0.93), location: 0.57),
                            .init(color: Color.clear, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                    
                    Spacer()
                    
                    LinearGradient(
                        stops: [
                            .init(color: Color.mmBackground.opacity(0.00), location: 0.00),
                            .init(color: Color.mmBackground.opacity(0.15), location: 0.30),
                            .init(color: Color.mmBackground.opacity(0.40), location: 0.65),
                            .init(color: Color.mmBackground.opacity(0.75), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
                .allowsHitTesting(false)
                
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Import Your Notes")
                                .foregroundStyle(Color.mmDark)
                                .fontWeight(.semibold)
                                .font(.system(size: 16))
                            
                            Text("Connect and add your favorite notes\napp to import notes into Rep.")
                                .font(.system(size: 14))
                                .lineSpacing(1)
                                .fontWeight(.medium)
                                .opacity(0.50)
                        }
                        .padding(.top)
                        
                        Spacer()
                    }
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Spacer()
                        NavigationLink(value: NavPathItem.pluginStore) {
                            ZStack {
                                Capsule()
                                    .frame(width: 120, height: 35)
                                    .foregroundStyle(Color.mmDark)
                                    .opacity(0.2)
                               
                                HStack(spacing: 5) {
                                    Text("Add Plugins")
                                        .foregroundStyle(Color.mmDark)
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                    
                                    Image(systemName: "powerplug.portrait")
                                        .foregroundStyle(Color.mmDark)
                                        .font(.system(size: 14))
                                }.padding(.horizontal)
                            }
                        }
                        .padding(.trailing, 7)
                    }.padding(.bottom, 14)
                }
                .padding(.leading)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .glassEffect(.regular, in: .rect(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.mmDark.opacity(0.16), lineWidth: 1)
            }
        }
        .padding(.horizontal)
    }
}


#Preview {
    PluginListCard()
}
