/* custom UI elements, markdown, bullets, headings,
 and list custom rendering styles for AI chat
 and trasncription notes defined here */
import SwiftUI
import Foundation



struct AINotesContentView: View {
    let text: String
    
    private var lines: [String] {
        text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, textLine in
                if index == 0 {
                    Text(textLine)
                        .fontWeight(.bold)
                        .padding(.vertical, 6)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(Color.mmDark)
                        Text(textLine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical)
        .font(.system(size: 16))
        .lineSpacing(7)
        .fontWeight(.medium)
        .fontDesign(.rounded)
        .lineLimit(nil)
        .textSelection(.enabled)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}


