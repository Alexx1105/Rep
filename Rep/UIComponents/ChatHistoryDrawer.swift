//
//  ChatHistoryDrawer.swift
//  Rep
//
//  Created by alex haidar on 11/20/26.
//
import SwiftUI
import Foundation
import SwiftData



struct ChatHistoryDrawer: View {
    var onClose: () -> Void
    var onSelect: (String) -> Void
    var onNewChat: () -> Void = {}
    
    @Query private var exisitngChats: [OpenAIChat]
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 30).foregroundStyle(Color.mmBackground)
                RoundedRectangle(cornerRadius: 30).fill(.clear).glassEffect(.regular, in: .rect(cornerRadius: 30))
                
                VStack {
                    HStack(alignment: .top) {
                        Text("Chats").font(.system(size: 20, weight: .semibold)).fontDesign(.rounded).foregroundStyle(.mmDark)
                            .padding(.leading)
                        Spacer()
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark").foregroundStyle(.mmDark)
                            
                        }.buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .accessibilityLabel("Close")
                        
                    }.padding(.top)
                        .padding(.trailing)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(exisitngChats, id: \.openaiId) { chat in
                                Button {
                                    onSelect(chat.openaiId)
                                } label: {
                                    Text(chat.content).font(.system(size: 17, weight: .medium)).foregroundStyle(.mmDark)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.trailing)
                                        .padding(.top)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [.clear, .black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                            
                            Rectangle().fill(.black)
                            
                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 80)
                        }
                    }
                    .padding(.top)
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            onNewChat()
                        } label: {
                            HStack {
                                Text("Chat").fontDesign(.rounded).fontWeight(.medium)
                                Image(systemName: "plus")
                                    .padding(.vertical, 6)
                            }
                            .foregroundStyle(Color.mmBackground)
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color.mmDark)
                        .buttonBorderShape(.capsule)
                        .padding(.bottom)
                    }.padding(.trailing)
                    
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
            .frame(width: geometry.size.width * 2 / 3)
            .frame(maxHeight: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 30))
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { drag in
                        let horizontal = drag.translation.width
                        let vertical = drag.translation.height
                        guard horizontal <= -50, -horizontal > abs(vertical) else { return }
                        onClose()
                    }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}



#Preview {
    let container: ModelContainer = {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: OpenAIChat.self, configurations: configuration)
            let titles = [
                "Weekly planning",
                "Ideas for the next release",
                "Meeting notes and action items",
                "SwiftUI navigation patterns",
                "Research summary",
                "Project roadmap",
                "A longer chat title that should truncate neatly in the sidebar",
                "Morning brainstorm",
                "Design feedback",
                "Notes from today's lecture",
                "Preparing for the presentation",
                "API integration questions",
                "Weekend reading list",
                "Product launch checklist",
                "Customer interview takeaways",
                "Organizing my notes",
                "Performance improvements",
                "New feature ideas",
                "Team retrospective",
                "Learning SwiftData",
                "Drafting a project proposal",
                "Travel planning",
                "Monthly goals",
                "Follow-up questions"
            ]
            
            for (index, title) in titles.enumerated() {
                container.mainContext.insert(OpenAIChat(
                    content: title,
                    openaiId: "preview-chat-\(index)"
                ))
            }
            try container.mainContext.save()
            return container
        } catch {
            fatalError("Failed to create chat history preview: \(error)")
        }
    }()
    
    return ChatHistoryDrawer(onClose: {}, onSelect: { _ in })
        .modelContainer(container)
}
