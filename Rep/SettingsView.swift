//
//  SettingsView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/23/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissSettingsTab
    @Environment(\.modelContext) var context
    
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
   
    @AppStorage("appearence.toggle") private var toggleEnabled = false
    @AppStorage("hypermodetoggle") private var hyperToggleEnabled: Bool = false
    @AppStorage("desktop.pollingEnabled") private var isPollingEnabled = false
    
    @ObservedObject var AutoSync = SyncController.shared
     
    var showUserEmail: [UserEmail] = []
    
    @State private var presentPopover: Bool = false
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading) {
                
                HStack(spacing: 3) {
                    NavigationLink("Terms Of Use", destination: TOSPage())
                        .font(.system(size: 10)).lineSpacing(3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gray)
                        .buttonStyle(.glass)
                        .padding(.top)
                    
                }.padding(.leading)
                
                HStack(spacing: 13) {
                    
                    Text("Settings")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                        .padding(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
              
//                    Button("Upgrade Plan") {
//                        withAnimation {
//                            presentPopover = true
//                        }
//                    }
//                    .fontWeight(.semibold)
//                    .font(.system(size: 12))
//                    .buttonStyle(.glassProminent)
//                    .padding(.trailing)
                }
                .frame(maxWidth: .infinity, maxHeight: 150)
                 
              
               
                
                
                VStack(alignment: .leading) {
                    Divider()
                    HStack(alignment: .top, spacing: 10) {
                        
                        Image(systemName: "circle.lefthalf.filled.inverse").offset(y: 7)
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .opacity(textOpacity)
                        
                        Toggle("Appearance", isOn: $toggleEnabled)
                            .fontWeight(.semibold)
                            .opacity(textOpacity)
                            .tint(.blue)
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                    
                    Text("Toggle appearence to have\ndark mode as the standard")
                        .font(.system(size: 14)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.50)
                        .padding(.leading)
                       
                    
                    Divider()
                    
                    HStack(alignment: .top ) {
                        HStack(spacing: 10) {
                            
                            Image("notionLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .opacity(textOpacity)
                            
                            Toggle("Auto Sync", isOn: $AutoSync.isAutoSync)
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                                .tint(.blue)
                                .onChange(of: AutoSync.isAutoSync) { _, newValue in
                                    print("auto sync toggled in settings view: \(newValue)")
                                }
                            
                        }.frame(alignment: .leading)
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                    Text("Toggle Auto Sync to enable on-demand\nsyncing between your Notion and your\nimported notes")
                        .font(.system(size: 14)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.50)
                        .padding(.leading)
                    
                    Divider().padding(.bottom, 7)
                    HStack(alignment: .top ) {
                        HStack(spacing: 10) {
                            Image(systemName: "macbook.and.iphone").font(.system(size: 15))
                                .opacity(textOpacity)
                            
                            Toggle("Rep Desktop", isOn: $isPollingEnabled)
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                                .tint(.blue)
                                .onChange(of: isPollingEnabled) { _, enabled in
                                    if enabled {
                                        RepDesktopPoller.shared.startPollingNotes(context: context)
                                    } else {
                                        RepDesktopPoller.shared.stopPollingNotes()
                                    }
                                }
                            
                        }.frame(alignment: .leading)
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                       
                    
                    Text("Toggle to receive transcripts and notes from\nmeetings recorded with Rep Desktop on your\nMac, directly on your iPhone.")
                        .font(.system(size: 14)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.50)
                        .padding(.leading)
                    
                    Divider()
                }
                Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.mmBackground)
            .overlay {
                if presentPopover {
                    PaymentMenuCard(isPresented: $presentPopover)
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
}



#Preview {
    SettingsView()
        .environment(\.sizeCategory, .large)
}

