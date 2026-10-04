import SwiftUI


struct HyperToggleCard: View {
    @Binding var isPresented: Bool
    @Binding var hyperToggleEnabled: Bool
    @Environment(\.colorScheme) var colorScheme
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    var body: some View {
        
        ZStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Toggle("Hyper Mode", isOn: $hyperToggleEnabled)
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                        .tint(.blue)
                        .onChange(of: hyperToggleEnabled) { oldValue, newValue in
                            print("hyper mode toggled in settings view: \(newValue)")
                        }
                    
                }.padding(.trailing)
                
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


struct RepeatToggleCard: View {
    @Binding var isPresented: Bool
    @Binding var repeatEnabled: Bool
    @Environment(\.colorScheme) var colorScheme
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    var body: some View {
        
        ZStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Toggle("Enable Repeat", isOn: $repeatEnabled)
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                        .tint(.blue)
                        .onChange(of: repeatEnabled) { oldValue, newValue in
                            print("hyper mode toggled in settings view: \(newValue)")
                        }
                    
                }.padding(.trailing)
                
                VStack(alignment: .leading) {
                    Text("Enable Repeat to cycle through these\nnotes again after every note has been shown.")
                        .font(.system(size: 14)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.50)
                }
            }.padding(.leading)
        }
    }
}



#Preview {
    HyperToggleCard(isPresented:  .constant(true), hyperToggleEnabled: .constant(false))
}

#Preview {
    RepeatToggleCard(isPresented: .constant(true), repeatEnabled: .constant(true))
}
