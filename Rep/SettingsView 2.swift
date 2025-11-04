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
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading) {
                
                HStack(spacing: 10) {
                    
                    
                    Text("Settings")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                    Spacer()
                    
//                    NavigationLink(destination: SignOutView()) {
//                        Text("Log out")
//                            .fontWeight(.regular)
//                            .foregroundStyle(Color.red)
//                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: 230)
                .padding(.horizontal, 25)
               
                
                VStack(alignment: .leading) {
                    Divider()
                    HStack(alignment: .top) {
                        
                        Toggle("Appearence", isOn: $toggleEnabled)
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
         
            
        }
    }
}



#Preview {
    SettingsView()
}
