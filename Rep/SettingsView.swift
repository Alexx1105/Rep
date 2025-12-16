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
                        
                    }.frame(maxWidth: 370)
                        .padding(.leading)
                    
                    
                    Text("Toggle appearence to have\ndark mode as the standard")
                        .font(.system(size: 16)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.25)
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
}
