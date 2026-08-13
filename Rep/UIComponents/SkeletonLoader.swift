import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct SkeletonLoader: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Rectangle().frame(maxWidth: .infinity, maxHeight: 37).cornerRadius(10)
            .opacity(isAnimating ? 0.5 : 0.2)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true  }
            .foregroundStyle(Color.gray)
            .padding()
        
    }
}

#Preview {
    SkeletonLoader()
}
