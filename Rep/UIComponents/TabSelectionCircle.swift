import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct TabSelectionCircle: View {
    var selectedTab: Bool
    var body: some View {
        Circle()
            .fill(selectedTab ? Color.blue.opacity(0.7) : Color.mmBackground)
            .stroke(selectedTab ? Color.blue : Color.gray, lineWidth: 0.5)
            .frame(width: 32, height: 32)
            .transition(.move(edge: .trailing).combined(with: .slide))
            .padding(.leading, 1)
            .overlay { Image(systemName: "checkmark").foregroundStyle(Color.checkmark)}
    }
}

#Preview {
    TabSelectionCircle(selectedTab: true)     ///selection checkbox
}
