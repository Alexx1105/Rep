//
//  CategoryTabs.swift
//  Rep
//
//  Created by alex haidar on 11/1/26.
/* Category tabs for filtering tabs in
   the main menu view based on notes provider */
import SwiftUI


enum CategoryFilter: String, CaseIterable {
    case audioTranscriptionNotes = "Transcriptions"
    case aiChatNotes = "AI Chats"
    case pluginProivderNotes = "Imported Notes"
    case allNotes = "All Notes"
    
    var icon: String {
        switch self {
        case .allNotes:
            return "rectangle.stack"
        case .aiChatNotes:
            return "text.line.3.summary"
        case .pluginProivderNotes:
            return "square.and.arrow.down"
        case .audioTranscriptionNotes:
            return "waveform"
        }
    }
}


struct CategoryTabs: View {
    @Binding var selectedFilterCategory: CategoryFilter
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                ForEach(CategoryFilter.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.snappy(duration: 0.3)) {
                            selectedFilterCategory = selectedFilterCategory == category ? .allNotes : category
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.icon)
                                .foregroundStyle(Color.mmDark)
                                .padding(.vertical, 9)
                            
                            if selectedFilterCategory == category {
                                Text(category.rawValue)
                                    .lineLimit(1)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.mmDark)
                                    .fontDesign(.rounded)
                                    .padding(.vertical, 9)
                            }
                            
                        }.padding(.horizontal)
                            .background(Capsule(style: .circular)
                                .fill(selectedFilterCategory == category ? Color.blue : Color.gray).opacity(0.3)
                                .frame(maxWidth: .infinity, maxHeight: 55))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
    }
}



#Preview {
    @Previewable @State var selectedCategory: CategoryFilter = .allNotes

    ScrollView(.horizontal, showsIndicators: true) {
        CategoryTabs(selectedFilterCategory: $selectedCategory)
            .padding(.horizontal)
    }
}
