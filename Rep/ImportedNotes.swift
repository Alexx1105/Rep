//
//  ContentView.swift
//  MuscleMemory
//
//  Created by alex haidar on 4/13/24.
//

import SwiftUI
import Foundation
import SwiftData


struct ImportedNotes: View {
    var pageID: String
    var filterPage: [UserPageContent] {
        guard !pageID.isEmpty else { return [] }
        return pageContent.filter{($0.userPageId) == pageID }
    }
    
    var filterTitle: [UserPageTitle] {
        pageTitle.filter{($0.titleID) == pageID }
    }
    @Environment(\.dismiss) var dismissTab
    @Environment(\.modelContext) var modelContextPage
    
    @Query var pageContent: [UserPageContent]
    @Query var pageTitle: [UserPageTitle]
    
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @State private var loading = false
    @State private var didLoad = false
    
    public func callEndpoint() async {
        ImportUserPage.shared.modelContextPagesStored(pagesContext: modelContextPage)
        print("page data loaded from cache ✅")
    }
    
    
    
    var body: some View {
        
        NavigationView {
            
            VStack {
                HStack(spacing: 7) {
                    
                    Button {
                           dismissTab()
                    } label: {
                        Image(systemName: "arrow.backward").foregroundStyle(Color.mmDark.opacity(0.8)).padding(13)
                    }.glassEffect()
                    
                    if let emojis = filterTitle.first?.emoji, let title = filterTitle.first?.plain_text {
                        Text("\(emojis)")
                        Text("\(title)")
                            .fontWeight(.semibold)
                        
                    } else {
                        Rectangle()
                            .cornerRadius(5)
                            .frame(width: 150, height: 20)
                            .opacity(0.1)
                        
                    }
                    Spacer()
                    Button(action: {}) {         //TO-DO: modify to prompt premium tier panel
                        Image("mmProIcon")
                        
                    }.glassEffect()
                }
                .frame(maxWidth: 370)
                .padding(.top, 5)
                
                
                Spacer()
                Divider()
                
                
                VStack {
                    
                    List(filterPage, id: \.self) { block in
                        
                        Text(block.userContentPage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                            .font(.system(size: 16)).lineSpacing(1)
                            .listRowBackground(Color.mmBackground)
                            .listRowSeparator(.hidden)
                        
                    }
                    .listStyle(.plain)
                    
                }
                .fontWeight(.medium)
               
            }
            .background(Color.mmBackground)
        }
        .task {
             await callEndpoint()
        }
    }
}



#Preview {
    ImportedNotes(pageID: "")
}


