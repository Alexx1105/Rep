import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct PickerView: View {
    enum PickerType: String, CaseIterable {
        case transcript = "Transcript"
        case notes = "Notes"
    }
    
    @Binding var pickerType: PickerType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PickerType.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 1.0)) {
                        pickerType = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(pickerType == item ? Color.intervalBlue : Color.white)
                        .frame(width: 67, height: 45)
                        .background {
                            if pickerType == item {
                                Capsule().fill(Color.mmBackground).glassEffect(.regular).opacity(0.5)
                                    
                            }
                        }
                }
            }
        }
        .padding(2)
        .background(Color.mmLight)
        .clipShape(Capsule())
    }
}

#Preview {
    PickerView(pickerType: .constant(.notes))
}
