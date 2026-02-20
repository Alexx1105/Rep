//
//  ContentView.swift
//  MuscleMemory
//
//  Created by alex haidar on 4/13/24.
//

import SwiftUI
import Foundation
import SwiftData
import OSLog

struct ImportedNotes: View {
    let pageID: String
    
    var filterTitle: [UserPageTitle] {
        pageTitle.filter{($0.titleID) == pageID }
    }
    
    @Environment(\.dismiss) var dismissTab
    @Environment(\.modelContext) var context
    
    @Query var pageTitle: [UserPageTitle]

    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    
    enum ErrorDefinition: Error {
        case emptyContent
    }
    
    @State var pageBlocks: [UserPageContent] = []
    
    @MainActor
    func fetchPageContent(context: ModelContext) throws -> [UserPageContent] {
        
        let descriptor = FetchDescriptor<UserPageContent>(predicate: #Predicate { $0.userPageId == pageID }, sortBy: [SortDescriptor(\.id, order: .forward)])
        let result = try context.fetch(descriptor)
      
        guard !result.isEmpty else { throw ErrorDefinition.emptyContent }
        return result
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
                    
                }
                .frame(maxWidth: 370)
                .padding(.top, 5)
                
                
                Spacer()
                Divider()
                
                
                VStack {
                    
                    List(pageBlocks, id: \.self) { block in
                        
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
            do {
                pageBlocks = try fetchPageContent(context: context)
               
            } catch {
                print("function call failure: \(error.localizedDescription)")
            }
        }
    }
}



#Preview {
    ImportedNotes(pageID: "")
}


