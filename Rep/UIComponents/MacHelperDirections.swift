import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit


struct MacHelperDirections: View {
    @State var desktopUrlLink: URL?
    
    var body: some View  {
        VStack {
            HStack(alignment: .top) {
                Capsule().frame(width: 50, height: 5).padding(.top, 10)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 25).foregroundStyle(Color.gray).opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Use Rep Desktop on your Mac").font(.system(size: 14, weight: .bold, design: .rounded))
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
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("1.  Enable Rep Desktop toggle in settings")
                    
                    Image(systemName: "switch.2")
                        .font(.system(size: 15, weight: .regular))
                }
                
                Text("2.  Open the App Store on your Mac")
                
                Text("3.  Search for Rep Desktop Helper and download\n(or use the download button below)")
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("4.  Sign in with Apple in both apps to receive and sync your summarized notes.")
                    .fixedSize(horizontal: false, vertical: true)
                 
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("5.  Allow accessibility permissions")
                    
                    Image(systemName: "accessibility")
                        .font(.system(size: 15, weight: .regular))
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("6.  Enable notifications for Rep Desktop.")
                    
                    Image(systemName: "bell.badge")
                        .font(.system(size: 15, weight: .regular))
                }
                
                let appStoreURL: URL = URL(string: "https://www.apple.com/app-store/")!
                let urlSwap: URL = desktopUrlLink ?? appStoreURL
                ShareLink(item: urlSwap) {
                    
                    HStack(spacing: 8) {
                        Text("Download Rep Desktop").fontWeight(.semibold)
                        Image(systemName: "arrow.up.right").fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.kimchiLabs)
                }
                .tint(Color.intervalBlue)
                .buttonStyle(.glassProminent)
                .padding(.top, 10)
             
                
                
            }
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(Color.mmDark)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top)
            
            .padding(.horizontal, 28)
            
        }
        .task {
            let repDesktopUrl = await FetchAppStoreUrl.fetchDesktopUrl()
            desktopUrlLink = repDesktopUrl.flatMap(URL.init(string:))
        }
    }
}



#Preview {
    MacHelperDirections()
}
