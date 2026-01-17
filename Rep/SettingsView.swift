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
    
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
   
    @AppStorage("appearence.toggle") private var toggleEnabled = false
    @AppStorage("hypermodetoggle") private var hyperToggleEnabled: Bool = false
    @AppStorage("auto.sync") private var isAutoSync: Bool = false
  
    @Environment(\.modelContext) var modelContext
     
    var showUserEmail: [UserEmail] = []
    
    @State private var presentPopover: Bool = false
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading) {
                
                HStack(spacing: 13) {
                    
                    
                    Text("Settings")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                        .padding(.leading)
                  
                        .frame(maxWidth: .infinity, alignment: .leading)
                     
                    
                    Button("Upgrade Plan"){
                        withAnimation {
                            presentPopover = true
                        }
                    }
                    .fontWeight(.semibold)
                    .font(.system(size: 12))
                    .buttonStyle(.glassProminent)
                    .padding(.trailing)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 235)
              
               
                
                
                VStack(alignment: .leading) {
                    Divider()
                    HStack(alignment: .top) {
                        
                        Toggle("Appearance", isOn: $toggleEnabled)
                            .fontWeight(.semibold)
                            .opacity(textOpacity)
                            .tint(.blue)
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                    
                    Text("Toggle appearence to have\ndark mode as the standard")
                        .font(.system(size: 16)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.25)
                        .padding(.leading)
                       
                    
                    Divider()
                    
                    HStack(alignment: .top ) {
                        HStack(spacing: 15) {
                            
                            Text("Pro").foregroundStyle(Color.intervalBlue)
                                .font(.system(size: 16))
                                .fontWeight(.heavy)
                                .overlay {
                                    Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                                        .frame(width: 40, height: 21)
                                }.padding(.leading, 5)
                            
                            Toggle("Auto Sync", isOn: $isAutoSync)
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                                .tint(.blue)
                                .onChange(of: isAutoSync) { oldValue, newValue in
                                    print("auto sync toggled in settings view: \(newValue)")
                                }
                            
                        }.frame(alignment: .leading)
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                    Text("Toggle Auto Sync to enable on-demand\nsyncing between your notion and your imported notes")
                        .font(.system(size: 16)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.25)
                        .padding(.leading)
                    
                    Divider()
                    
                    
                    HStack(alignment: .top) {
                        
                        HStack(spacing: 15) {
                            
                            Text("Pro").foregroundStyle(Color.intervalBlue)
                                .font(.system(size: 16))
                                .fontWeight(.heavy)
                                .overlay {
                                    Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                                        .frame(width: 40, height: 21)
                                }.padding(.leading, 5)
                           
                            Toggle("Hyper Mode", isOn: $hyperToggleEnabled)
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                                .tint(.blue)
                                .onChange(of: hyperToggleEnabled) { oldValue, newValue in
                                    print("hyper mode toggled in settings view: \(newValue)")
                                }
                            
                        }.frame(alignment: .leading)
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                    
                    Text("Toggle Hyper Mode to have a shorter\ninterval selection option set")
                        .font(.system(size: 16)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.25)
                        .padding(.leading)
                    
                    ZStack(alignment: .trailing) {
                        Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                            .frame(width: 140, height: 21)
                            .offset(x: 7)
                        
                        HStack(spacing: 3) {
                            Text("1hr, 2h30m, 3h40m →  ")
                                .font(.system(size: 16)).lineSpacing(3)
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                                .padding(.leading)
                            
                            Text("10m, 30m, 45m").foregroundStyle(Color.intervalBlue)
                                .font(.system(size: 16)).lineSpacing(3)
                                .fontWeight(.heavy)
                               
                            
                        }
                    }
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

