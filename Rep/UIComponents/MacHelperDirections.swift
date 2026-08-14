import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct MacHelperDirections: View {
    var body: some View  {
        VStack {
            HStack(alignment: .top) {
                Capsule().frame(width: 50, height: 5)
            }.padding(.top)
            
            ZStack {
                RoundedRectangle(cornerRadius: 30).foregroundStyle(Color.gray).opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Transcribe On Mac").font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.mmDark)
                    }
                    
                    HStack {
                        Image("repMini").resizable()
                            .frame(width: 25, height: 25)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 1))
                            path.addLine(to: CGPoint(x: 45, y: 1))
                        }
                        .stroke(Color.mmDark, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        .frame(width: 45, height: 2)
                        
                        Image(systemName: "macbook.gen2").font(.system(size: 25)).foregroundStyle(Color.mmDark)
                        
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 1))
                            path.addLine(to: CGPoint(x: 45, y: 1))
                        }
                        .stroke(Color.mmDark, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        .frame(width: 45, height: 2)
                        
                        Image(systemName: "iphone.gen3").font(.system(size: 25)).foregroundStyle(Color.mmDark)
                        
                    }
                }
            }.padding(.top)
            
            VStack(alignment: .leading, spacing: 14) {
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("1.  Enable Rep Desktop toggle in settings")
                    
                    Image(systemName: "switch.2")
                        .font(.system(size: 15, weight: .regular))
                }
                
                Text("2.  Open App Store on Mac")
                
                Text("3.  Search for Rep Desktop Helper and download")
                
                Text("4.  Sign in with Apple ID to auto sync Rep between your Mac and iPhone to receive summarized notes")
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("5.  Allow accessibility permissions")
                    
                    Image(systemName: "accessibility")
                        .font(.system(size: 15, weight: .regular))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("6.  Enable Notifications for Rep on Mac")
                    
                    Image(systemName: "bell.badge")
                        .font(.system(size: 15, weight: .regular))
                }
                
                let appStoreURL: URL = URL(string: "testing")!  //TODO: replace with app store url
                ShareLink(item: appStoreURL) {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(Color.intervalBlue)
                            .frame(width: 145, height: 30)
                            .glassEffect(.clear)
                        
                        HStack(spacing: 5) {
                            Text("Mac Download")
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundStyle(Color.kimchiLabs)
                    }
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(Color.mmDark)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top)
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

#Preview {
    MacHelperDirections()
}
