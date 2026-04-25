//
//  LiquidGlassTab.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/14/25.

///Store all SwiftUI struct components here from now on

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation


@MainActor
public final class Toast: ObservableObject {
    public static let shared = Toast()
    
    public func callToastOnPageLoad(_ bind: Binding<Bool>) async {
        bind.wrappedValue = true
        
        Task { @MainActor in
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation(.easeInOut(duration: 0.2)) {
                bind.wrappedValue = false
            }
        }
    }
}

struct RootTabs: View {
    @State private var showImportToast: Bool = false
    @StateObject private var toastManager = NotionDataManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView {
                    Tab("Menu", systemImage: "list.bullet") {
                        MainMenu(pageID: "pageID")
                    }
                    Tab("Settings", systemImage: "gear") {
                        SettingsView()
                    }
                    Tab("Import", systemImage: "plus.app") {
                        NotionImportPageView()
                    }
                    
                }.tabBarMinimizeBehavior(.never)
                    .background(Color.clear)
                
                    .overlay(alignment: .top) {
                        if showImportToast {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                ToastNotification()
                                    .transition(.move(edge: .top).combined(with: .blurReplace))
                                    .allowsHitTesting(false)
                                    .fixedSize(horizontal: false, vertical: false)
                                    .ignoresSafeArea(edges: .top).padding(.top, 1)
                            }
                        }
                    }
            }
        }
        
        .task(id: toastManager.isPageImportedNotification) {
            Task { @MainActor in
                guard self.toastManager.isPageImportedNotification else { return }
                await Toast.shared.callToastOnPageLoad($showImportToast)
            }
        }
    }
}


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

struct MainMenuTab: View {
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    let userPageTitle: UserPageTitle
    
    var body: some View {
        
        ZStack(alignment: .center) {
            Rectangle()
                .fill(.white.opacity(elementOpacityDark))
                .stroke(Color.mmBackground, lineWidth: 0.5)
                .foregroundStyle(Color.mmDark)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDark, lineWidth: 0.3))
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                
                Menu {
                    Text("DynamicRep Settings")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                        .opacity(0.5)
                    
                    NavigationLink(destination: DynamicRepControlsView(pageID: userPageTitle.pageID)) {
                        Label("Live activities", systemImage: "clock.badge")
                    }
                    
                } label: {
                    
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(Color.mmDark)
                        .opacity(0.8)
                        .frame(width: 35, height: 35)
                        .padding(5)
                }
                
                HStack {
                    if let emoji = userPageTitle.emoji {
                        Text(emoji)
                    }
                    Text(userPageTitle.text)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.mmDark)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
                
                Spacer()
                Image("arrowChevron")
                    .opacity(0.8)
                    .padding(.trailing)
                
            }
            .padding(.leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 57)
    }
}

struct SliderView: View {
    
    struct SliderOption {
        let label: String
        let symbolName: String
        let interval: DateComponents
    }
    
    
    var sliderOptions: [SliderView.SliderOption]
    
    let initialSelectedOption: Int
    let selectedOptionChanged: ((Int) -> Void)
    
    @State var position: CGFloat = 0
    @State var lastDragPosition: CGFloat = 0
    @State var visualPosition: CGFloat = 0
    @State var sliderWidth: CGFloat = 0
    @State var stopPositions: [CGFloat] = []
    
    let circleSize: CGFloat = 50
    let resistance: CGFloat = 0.90
    
    var body: some View {
        ZStack {
            Capsule()
                .frame(height: 55)
                .opacity(0.06)
                .glassEffect()
            
            HStack {
                Circle()
                    .glassEffect()
                    .foregroundStyle(Color.blue)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: visualPosition)
                    .offset(x: -circleSize / 2)
                    .gesture (
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                position = lastDragPosition + value.translation.width
                                position = max(position, 0)
                                position = min(position, sliderWidth)
                                
                                var closestStopPosition: CGFloat = 0
                                var minDistance: CGFloat = .greatestFiniteMagnitude
                                for i in 0..<stopPositions.count {
                                    if abs(stopPositions[i] - position - circleSize / 2) < minDistance {
                                        minDistance = abs(stopPositions[i] - position - circleSize / 2)
                                        closestStopPosition = stopPositions[i] - circleSize / 2
                                    }
                                }
                                
                                let resistanceDistance = minDistance - (minDistance * resistance * resistance)
                                withAnimation {
                                    if position < closestStopPosition {
                                        visualPosition = closestStopPosition - resistanceDistance
                                    } else {
                                        visualPosition = closestStopPosition + resistanceDistance
                                    }
                                }
                            }
                            .onEnded { _ in
                                var closestStopPosition: CGFloat = 0
                                var minDistance: CGFloat = .greatestFiniteMagnitude
                                var closestStopIndex = -1
                                for i in 0..<stopPositions.count {
                                    if abs(stopPositions[i] - position - circleSize / 2) < minDistance {
                                        minDistance = abs(stopPositions[i] - position - circleSize / 2)
                                        closestStopPosition = stopPositions[i] - circleSize / 2
                                        closestStopIndex = i
                                    }
                                }
                                
                                position = closestStopPosition
                                lastDragPosition = position
                                withAnimation {
                                    visualPosition = closestStopPosition
                                }
                                
                                selectedOptionChanged(closestStopIndex)
                            }
                    )
                
                Spacer()
            }
            .padding(.horizontal, circleSize / 2 + 55 - circleSize)
            .background {
                GeometryReader { geo in
                    HStack {}.onAppear {
                        sliderWidth = geo.size.width - circleSize - circleSize + 40
                        
                        var newStopPositions: [CGFloat] = []
                        newStopPositions.append(circleSize / 2)
                        let differenceBetweenStops = sliderWidth / (CGFloat(sliderOptions.count) - 1)
                        for i in 1..<sliderOptions.count {
                            newStopPositions.append(differenceBetweenStops * CGFloat(i) + circleSize / 2)
                        }
                        stopPositions = newStopPositions
                        
                        if initialSelectedOption < newStopPositions.count {
                            let startingPosition = newStopPositions[initialSelectedOption] - circleSize / 2
                            position = startingPosition
                            visualPosition = startingPosition
                            lastDragPosition = startingPosition
                        } else {
                            fatalError("In SliderView.Swift: Initial selected option is out of range.")
                        }
                    }
                }
            }
            
            ZStack {
                ForEach(Array(stopPositions.enumerated()), id: \.offset) { index, stopPosition in
                    HStack {
                        Image(systemName: sliderOptions[index].symbolName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25)
                            .offset(x: -8)
                            .offset(x: stopPosition)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.50)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 5)
    }
}

struct PaymentMenuCard: View {
    @Binding var isPresented: Bool
    //@StateObject private var paymentStore = PaymentStore()
    var body: some View {
        
        
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                Text("Unlock More With Pro").foregroundStyle(Color.mmDark)
                    .font(.system(size: 20))
                    .frame(maxWidth: 290, alignment: .leading)
                    .fontWeight(.semibold)
                
                
                Button("close") {
                    
                    withAnimation {
                        isPresented = false
                    }
                    
                }.buttonStyle(.glass)
                
            }.padding(.top)
            
            
            ZStack {
                Rectangle().foregroundStyle(Color.mmBackground).ignoresSafeArea()        ///solid overlay here
                    .frame(maxWidth: .infinity, maxHeight: 700)
                    .cornerRadius(25)
                    .padding()
                
                HStack(alignment: .top, spacing: 108) {
                    
                    VStack(spacing: 18) {
                        Text("Basic").foregroundStyle(Color.mmDark)
                            .fontWeight(.medium)
                            .font(.system(size: 20))
                        
                        HStack(spacing: 2) {
                            Text("$0").foregroundStyle(Color.mmDark)
                                .fontWeight(.black)
                                .font(.system(size: 32))
                            
                            Text("/mo").foregroundStyle(Color.mmDark)
                                .fontWeight(.medium)
                                .offset(y: 2)
                                .opacity(0.50)
                        }
                    }
                    
                    
                    VStack(spacing: 18) {
                        Text("Pro").foregroundStyle(Color.intervalBlue)
                            .font(.system(size: 20))
                            .fontWeight(.heavy)
                            .overlay {
                                Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                                    .frame(width: 52, height: 25)
                            }
                        
                        HStack(spacing: 2) {
                            Text("$8").foregroundStyle(Color.mmDark)
                                .fontWeight(.black)
                                .font(.system(size: 32))
                            
                            Text("/mo").foregroundStyle(Color.mmDark)
                                .fontWeight(.medium)
                                .offset(y: 2)
                                .opacity(0.50)
                        }
                    }
                }.frame(maxHeight: 630, alignment: .top)
                
                ZStack {
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 80) {
                            Text("• Unlimited plain text support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Unlimited plain text support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        HStack(spacing: 110) {
                            Text("• Unlimited LiveActivity flashcards").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Unlimited LiveActivity flashcards").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        HStack(spacing: 102) {
                            Text("• basic mode support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Hyper mode support").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        
                        HStack(spacing: 73) {
                            Text("• Import up to two pages at a time").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Emoji support 😄").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 313, alignment: .trailing)
                        
                        HStack(spacing: 98) {
                            Text("• first access to\nfuture supported\nnotion content\ntypes").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 300, alignment: .trailing)
                        
                        HStack(spacing: 98) {
                            Text("• Unlimited # of\nimported pages\nat a time").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 280, alignment: .trailing)
                        
                        HStack(spacing: 98) {
                            Text("• Imported notes\nauto-fetch latest\nchanges made\nin Notion").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 295, alignment: .trailing)
                    }
                }
                
                
                
                VStack {
                    HStack(alignment: .top) {
                        Divider().frame(maxHeight: 580)
                    }
                    
                    
                    
                    Button {
                        Task {
                            try await PaymentStore().runPaymentFlow()
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 30).glassEffect()
                            .frame(maxWidth: 350, maxHeight: 48)
                            .foregroundStyle(Color.intervalBlue)
                        
                        
                            .overlay {
                                Text("Coming Soon").foregroundStyle(Color.kimchiLabs)  //change back to "Upgrade" later
                                    .fontWeight(.heavy)
                                
                            }.padding(.bottom)
                    }.disabled(true)   //dont forgot to remove
                }.padding(.top, 5)
                
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 800)
        .background {
            Rectangle()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: 800)
                .glassEffect(.regular, in: .rect(cornerRadius: 35))         ///glass background here
            
        }
    }
}


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
                    //                    Text("Pro").foregroundStyle(Color.intervalBlue)
                    //                        .font(.system(size: 16))
                    //                        .fontWeight(.heavy)
                    //                        .overlay {
                    //                            Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                    //                                .frame(width: 40, height: 21)
                    //                        }
                    
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


struct ToastNotification: View {
    var body: some View {
        
        ZStack {
            Capsule()
                .frame(maxWidth: 248, maxHeight: 43)
                .glassEffect(.regular)
            
            HStack(alignment: .center, spacing: 15) {
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Page/s Successfully Imported")
                        .font(Font.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Color.mmDark)
                        .padding(.leading)
                    
                    Text("Close Out The Import Dialog")
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
    MainMenuTab(userPageTitle: UserPageTitle(pageID: "page ID", text: "title", emoji: "😄")) ///page tab
}


#Preview {
    RootTabs()                                ///liquid glass tab bar
}

#Preview {
    TabSelectionCircle(selectedTab: true)     ///selection checkbox
}

#Preview {
    VStack {
        SliderView(sliderOptions: [
            SliderView.SliderOption(label: "First", symbolName: "multiply.circle", interval: DateComponents(minute: 1)),
            SliderView.SliderOption(label: "Second", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 60)),
            SliderView.SliderOption(label: "Third", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 2, minute: 30)),
            SliderView.SliderOption(label: "Forth", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 3, minute: 40))
        ], initialSelectedOption: 1) { newOptionIndex in
            print("SLIDER 1 NEW OPTION SELECTED: \(newOptionIndex)")
        }
        SliderView(sliderOptions: [
            SliderView.SliderOption(label: "First", symbolName: "multiply.circle", interval: DateComponents()),
            SliderView.SliderOption(label: "First", symbolName: "timer", interval: DateComponents()),
            SliderView.SliderOption(label: "First", symbolName: "timer", interval: DateComponents())
            
        ], initialSelectedOption: 0) { newOptionIndex in
            print("Slider 2 NEW OPTION SELECTED: \(newOptionIndex)")
        }
    }
}


struct ChatView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var closeChatSheet
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    private var messagePlaceholder: String = "Upload notes or Ask..."
    @StateObject private var chatState = Chat.shared
    @State var showFilePicker: Bool = false
    @State var showCameraPicker: Bool = false
    @State var selectedPhoto: [PhotosPickerItem] = []
    @State var showPhotoPicker: Bool = false
    @State private var imageCaptured: UIImage?
    @State var fileUrls: [URL] = []
    
    var body: some View {
        ZStack {
            Color.mmBackground.ignoresSafeArea()
            ScrollView {
                VStack {
                    ForEach(0..<40) { _ in
                        Text("Testing chat text flow completion and how it fills up")
                            .fontWeight(.medium)
                            .lineLimit(nil)
                            .opacity(textOpacity)
                    }
                }.frame(maxWidth: .infinity)
                    .padding(.horizontal)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.02),
                                                      .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                      .init(color: Color.mmBackground.opacity(0.50), location: 0.05),
                                                      .init(color: Color.mmBackground.opacity(0.30), location: 0.10),]), startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            
            LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(1.00), location: 0.00),
                                                      .init(color: Color.mmBackground.opacity(1.00), location: 0.05),
                                                      .init(color: Color.mmBackground.opacity(0.30), location: 0.10),
                                                      .init(color: Color.mmBackground.opacity(0.05), location: 0.15),]), startPoint: .bottom, endPoint: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            
            VStack {
                HStack(alignment: .top) {
                    
                    Button {
                        withAnimation { closeChatSheet() }
                    } label: {
                        ZStack {
                            Circle().fill(Color.clear).glassEffect(.regular)
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.mmDark)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 25).fill(Color.clear).glassEffect( .regular, in: .rect(cornerRadius: 25))
                            .frame(width: 110, height: 45)
                        
                        HStack {
                            Menu {
                                Button {
                                    
                                } label: {
                                    Label("GPT-5.4", image: "")
                                }
                                
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmDark)
                                    .padding()
                            }
                            Button {
                                
                            } label: {
                                
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmDark)
                                    .padding()
                            }
                        }
                    }
                    
                }.padding(.top)
                    .padding(.horizontal)
                
                
                Spacer()
                VStack(alignment: .leading, spacing: 20) {
                    TextField(messagePlaceholder, text: $chatState.chat, axis: .vertical)
                        .lineLimit(1...10)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal)
                        .fontWeight(.medium)
                        .onSubmit {
                            Chat.sendChatMessage()
                        }
                    
                    HStack(alignment: .bottom) {
                        Menu {
                            Button {
                                
                            } label: {
                                Label("Take Photo", systemImage: "camera.fill")
                            }
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Upload Photo", systemImage: "photo")
                            }.onChange(of: selectedPhoto) {_, newValueItem in
                                //do {
                                Task {
                                    for item in newValueItem {
                                        let rawImageData: Data? = try? await item.loadTransferable(type: Data.self)
                                        let _ = UIImage(data: rawImageData ?? Data())
                                    }
                                }
                                //                                } catch {
                                //                                    print("upload error ❗️", ErrorDesc.photoUploadError)
                                //                                }
                            }
                            
                            Button {
                                showFilePicker = true
                            } label: {
                                Label("Upload File(s)", systemImage: "folder.fill")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).frame(maxWidth: 80, maxHeight: 30).opacity(0.2).foregroundStyle(Color.intervalBlue)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "plus.app").foregroundStyle(Color.intervalBlue)
                                    Text("Upload")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.intervalBlue)
                                }
                            }
                        }
                        
                        Spacer()
                        Button {
                            Chat.sendChatMessage()
                        } label: {
                            ZStack {
                                Circle().fill(Color.mmDark)
                                    .frame(maxWidth: 30, maxHeight: 30)
                                
                                Image(systemName: "arrow.up").foregroundStyle(Color.checkmark)
                                
                            }
                        }.padding(.trailing)
                    }
                }.padding(.leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.clear).glassEffect(.regular, in: .rect(cornerRadius: 30))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal))
                    .padding(.bottom)
            }
        }.sheet(isPresented: $showCameraPicker) {
            CameraPicker(onImagePicked: { image in
                imageCaptured = image
                showCameraPicker = false
            },
                         onCancel: {
                showCameraPicker = false
            }
            )
        }.sheet(isPresented: $showFilePicker) {
            DocPicker(contentType: [.item, .image, .folder, .fileURL], allowMultipleFileSelect: true) { url in
                fileUrls = url
            }
            
            List(fileUrls, id: \.self) { url in
                Text(url.lastPathComponent)
            }
        }.photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, maxSelectionCount: 10, matching: .images)
        
    }
}


#Preview {
    PaymentMenuCard(isPresented:  .constant(true))
}
#Preview {
    HyperToggleCard(isPresented:  .constant(true))
}

#Preview {
    SkeletonLoader()
}

#Preview {
    ToastNotification()
}

#Preview {
    ChatView()
}

