import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct HyperToggleCard: View {
    
    @Binding var isPresented: Bool
    @AppStorage("hypermodetoggle") private var hyperToggleEnabled: Bool = false
    @Environment(\.colorScheme) var colorScheme
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    var body: some View {
        
        ZStack {
            Rectangle().fill(.ultraThickMaterial)
                .stroke(Color.mmBackground, lineWidth: 0.3)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.mmDark, lineWidth: 0.3))
                .cornerRadius(15).padding(7)
                .frame(maxHeight: 130)
            
            
            VStack(alignment: .leading) {
                
                HStack(spacing: 3) {
                    Spacer()
                    
                    Toggle("Hyper Mode", isOn: $hyperToggleEnabled)
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                        .tint(.blue)
                        .onChange(of: hyperToggleEnabled) { oldValue, newValue in
                            print("hyper mode toggled in settings view: \(newValue)")
                        }
                    
                }.padding(.horizontal)
                
                
                VStack(alignment: .leading) {
                    Text("Toggle Hyper Mode to have a shorter\ninterval selection option set")
                        .font(.system(size: 14)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.50)
                    
                    
                    ZStack(alignment: .trailing) {
                        Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                            .frame(width: 120, height: 21)
                            .offset(x: 7)
                        
                        HStack(spacing: 3) {
                            Text("1hr, 2h30m, 3h40m →  ")
                                .font(.system(size: 14)).lineSpacing(3)
                                .fontWeight(.medium)
                                .opacity(textOpacity)
                            
                            
                            Text("10m, 30m, 45m").foregroundStyle(Color.intervalBlue)
                                .font(.system(size: 14)).lineSpacing(3)
                                .fontWeight(.semibold)
                            
                        }
                    }
                }
            }.padding(.leading)
        }
    }
}

#Preview {
    HyperToggleCard(isPresented:  .constant(true))
}
