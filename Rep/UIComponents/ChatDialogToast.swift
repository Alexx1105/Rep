import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct ChatDialogToast: View {
    var body: some View {
        
        ZStack {
            Capsule()
                .frame(maxWidth: 248, maxHeight: 43)
                .glassEffect(.regular)
            
            HStack(alignment: .center, spacing: 15) {
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notes Successfully Generated")
                        .font(Font.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Color.mmDark)
                        .padding(.leading)
                    
                    Text("Close Out The Chat Dialog")
                        .font(Font.system(size: 12, weight: .medium, design: .rounded)).opacity(0.5)
                        .padding(.leading)
                }
                
                ZStack {
                    Circle()
                        .frame(maxWidth: 35, maxHeight: 35)
                        .foregroundStyle(Color.intervalBlue)
                    
                    Image(systemName: "checkmark.circle").font(.system(size: 17)).foregroundStyle(Color.kimchiLabs)
                }
            }
        }
    }
}

#Preview {
    ChatDialogToast()
}
