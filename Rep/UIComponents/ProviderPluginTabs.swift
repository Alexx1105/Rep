//
//  ProviderPluginTabs.swift
//  Rep
//
//  Created by alex haidar on 10/4/26.
//
import SwiftUI
import Foundation


struct PluginListTab: View {
    let index: Int
    var body: some View {
        
        Button {
            
        } label: {
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 5).frame(width: 25, height: 25)
                        .foregroundStyle(Color.mmDark).opacity(0.5)
                    
                    Text("Notion")
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
    var body: some View {
        Button {
            
        } label: {
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 5).frame(width: 25, height: 25)
                        .foregroundStyle(Color.mmDark).opacity(0.5)
                    
                    Text("Notion")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.mmDark)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    ZStack {
                        Circle().frame(width: 45, height: 45)
                            .foregroundStyle(Color.gray).opacity(0.2)
                        
                        Image(systemName: "plus").foregroundStyle(Color.mmDark)
                    }
                }
                Divider()
            }
        }
    }
}



#Preview {
    PluginListTab(index: 1)
}

#Preview {
    PluginStoreTab()
}
