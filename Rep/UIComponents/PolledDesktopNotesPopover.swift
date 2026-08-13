//
//  UI.swift
//  Rep
//
//  Created by alex haidar on 8/12/26.
//
import SwiftUI
import Foundation
import SwiftData



struct PolledDesktopNotesPopover: View {
    @Binding var isPresented: Bool
    @Query var importedDesktopNotes: [RepDesktopTranscription]
    @Environment(\.modelContext) var context
    
    @State private var seenDesktopNotes: Set<String> = []
    
    private var visibleDesktopNotes: [RepDesktopTranscription] {
        importedDesktopNotes.filter { desktopNotes in
            !seenDesktopNotes.contains(desktopNotes.userId)
        }
    }
    
    
    
    private var bottomBlur: some View {
        LinearGradient(gradient: Gradient(colors: [Color.mmBackground.opacity(0),
                                                   Color.mmBackground.opacity(0.6),
                                                   Color.mmBackground]),startPoint: .top, endPoint: .bottom)
        .frame(height: 80)
        .allowsHitTesting(false)
    }
    
    var topBlur: some View {
        LinearGradient(gradient: Gradient(colors: [Color.mmBackground,
                                                   Color.mmBackground.opacity(0.6),
                                                   Color.mmBackground.opacity(0)]),startPoint: .top, endPoint: .bottom)
        .frame(height: 20)
        .allowsHitTesting(false)
    }
    
    
    var body: some View {
        Color.clear.frame(width: 0, height: 0).sheet(isPresented: $isPresented) {
            VStack {
                Spacer(minLength: 50)
                HStack(alignment: .center, spacing: 5) {
                    Image(systemName: "macbook.and.iphone")
                        .foregroundStyle(Color.mmDark)
                        .font(.system(size: 20))
                    
                    Text("Sent from your Mac").font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.mmDark)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                        seenDesktopNotes.formUnion(visibleDesktopNotes.map(\.userId))
                    } label: {
                        ZStack {
                            Circle().fill(Color.blue).glassEffect(.clear)
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.mmDark)
                                .font(.system(size: 20))
                        }
                    }
                    
                }.frame(maxHeight: 35)
                    .padding(.vertical)
                    .padding(.horizontal)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .frame(maxWidth: .infinity, maxHeight: 350)
                        .foregroundStyle(Color.mmBackground)
                    
                    ScrollView {
                        ForEach(visibleDesktopNotes, id: \.userId) { importedNote in
                            VStack(spacing: 23) {
                                HStack(alignment: .top, spacing: 12) {
                                    Circle().frame(width: 12, height: 12)
                                        .padding(.top).frame(height: 4)
                                        .foregroundStyle(Color.babyBlue)
                                        .padding(.leading)
                                    
                                    Text(importedNote.fullNotes.prefix(40))
                                        .font(.system(size: 16, weight: .medium))
                                        .truncationMode(.tail)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "waveform.mid").font(.system(size: 20))
                                        .foregroundStyle(Color.mmDark)
                                        .padding(.trailing, 35)
                                    
                                }.padding(.leading)
                                    .padding(.top).frame(height: 22)
                                
                                Divider()
                                    .padding(.horizontal)
                                    .padding(.leading)
                            }
                        }
                    }
                    .contentMargins(.vertical, 20, for: .scrollContent)
                    
                    VStack(spacing: 0) {
                        topBlur
                        Spacer()
                        bottomBlur
                    }
                }
                .frame(height: 350)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal)
            }.presentationDetents([.fraction(0.5)])
        }
    }
}


#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: RepDesktopTranscription.self,
        configurations: configuration
    )
    
    let previewNotes = [
        RepDesktopTranscription(
            userId: "preview-1",
            fullTranscript: "Launch planning transcript",
            fullNotes: "Launch plan review",
            createdAt: "2026-08-12T09:00:00Z"
        ),
        RepDesktopTranscription(
            userId: "preview-2",
            fullTranscript: "Product discussion transcript",
            fullNotes: "Product design decisions and next steps",
            createdAt: "2026-08-12T10:30:00Z"
        ),
        RepDesktopTranscription(
            userId: "preview-3",
            fullTranscript: "Weekly meeting transcript",
            fullNotes: "Weekly meeting notes with a deliberately long title for truncation testing",
            createdAt: "2026-08-12T13:15:00Z"
        ),
        RepDesktopTranscription(
            userId: "preview-4",
            fullTranscript: "Quick follow-up transcript",
            fullNotes: "Quick follow-up",
            createdAt: "2026-08-12T15:45:00Z"
        )
    ]
    
    for note in previewNotes {
        container.mainContext.insert(note)
    }
    
    return PolledDesktopNotesPopover(isPresented: .constant(true))
        .modelContainer(container)
}
