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
    @State private var showGeneratedChat: Bool = false
    @StateObject private var importManager = NotionDataManager.shared
    @StateObject private var chatGenerationManager = AIRequestManager.shared
    
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
                        if showImportToast {                                ///for notion imports
                            withAnimation(.easeInOut(duration: 0.2)) {
                                ToastNotification()
                                    .transition(.move(edge: .top).combined(with: .blurReplace))
                                    .allowsHitTesting(false)
                                    .fixedSize(horizontal: false, vertical: false)
                                    .ignoresSafeArea(edges: .top).padding(.top, 1)
                            }
                        }
                        
                        if showGeneratedChat {                              /// for AI generated notes
                            withAnimation(.easeInOut(duration: 0.2)) {
                                ChatDialogToast()
                                    .transition(.move(edge: .top).combined(with: .blurReplace))
                                    .allowsHitTesting(false)
                                    .fixedSize(horizontal: false, vertical: false)
                                    .ignoresSafeArea(edges: .top).padding(.top, 1)
                            }
                        }
                    }
            }
        }
        
        .task(id: importManager.isPageImportedNotification) {
            Task { @MainActor in
                guard self.importManager.isPageImportedNotification else { return }
                await Toast.shared.callToastOnPageLoad($showImportToast)
            }
        }
        
        .task(id: chatGenerationManager.isNotesGenerated) {
            Task { @MainActor in
                guard self.chatGenerationManager.isNotesGenerated else { return }
                await Toast.shared.callToastOnPageLoad($showGeneratedChat)
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
    
    let userPageTitle: UserPageTitle?
    let openaiChatTitle: OpenAIChat?
    
    let dataSource: CombinedDataSource
    
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
                    
                    NavigationLink(destination: DynamicRepControlsView(pageID: userPageTitle?.pageID ?? "", dataSource: dataSource)) {
                        Label("Live activities", systemImage: "clock.badge")
                    }
                    
                } label: {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(Color.mmDark)
                        .opacity(0.8)
                        .frame(width: 35, height: 35)
                        .padding(5)
                }
                
                HStack(spacing: 10) {
                    if let emoji: String = userPageTitle?.emoji {
                        Text(emoji)
                    }
                    
                    if openaiChatTitle?.content != nil {
                        Image("openaiLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .opacity(textOpacity)
                        
                        Text(openaiChatTitle?.content ?? "OpenAI Chat")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    
                    if userPageTitle?.text != nil {
                        Image("notionLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .opacity(textOpacity)
                        
                        Text(userPageTitle?.text ?? "")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
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
    MainMenuTab(userPageTitle: UserPageTitle(pageID: "page ID", text: "title", emoji: "😄"),
                openaiChatTitle: OpenAIChat(content: "", openaiId: ""), dataSource: .notionContent(UserPageTitle(pageID: "", text: "")))   ///page tab
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
    @Environment(\.modelContext) private var context
    
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    private var messagePlaceholder: String = "Upload notes or Ask..."
    
    @StateObject private var chatState = Chat.shared
    @State var showFilePicker: Bool = false
    @State var showCameraPicker: Bool = false
    @State var selectedPhotos: [PhotosPickerItem] = []
    @State var showPhotoPicker: Bool = false
    @State private var imageCaptured: UIImage?
    @State var fileUrls: [URL] = []
    @State public var isNewChat: Bool = false
    @State var isGenerating: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isCircleVisible: Bool = false
    @State private var isCirclePulsing: Bool = false
    @State var showEmptyState: Bool = false

    @FocusState private var isChatFocused: Bool
    
    @AppStorage("hasSeenEmptyState") var isEmptyStateSeen: Bool = false


    var body: some View {
        ZStack {
            Color.mmBackground.ignoresSafeArea()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        Spacer(minLength: 65)
                        
                        if isCircleVisible {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .frame(width: 18, height: 18)
                                    .opacity(isCirclePulsing ? 1.0 : 0.25)
                                    .scaleEffect(isCirclePulsing ? 1.2 : 0.8)
                                
                                Text("Generating...")
                                    .opacity(isCirclePulsing ? 0.8 : 0.25)
                                    .fontDesign(.rounded)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    isCirclePulsing.toggle()
                                }
                            }
                            .onDisappear {
                                isCirclePulsing = false
                            }
                        }
                        
                        ForEach(Chat.shared.responseMessage, id: \.id) { response in
                            Text(response.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                                .font(.system(size: 16)).lineSpacing(3).fontWeight(.medium)
                                .listRowBackground(Color.mmBackground)
                                .lineLimit(nil)
                                .transition(.opacity.combined(with: .blurReplace))
                                .textSelection(.enabled)
                        }.animation(.easeOut(duration: 0.3), value: Chat.shared.responseMessage.count)
                        
                        Spacer(minLength: keyboardHeight > 0 ? keyboardHeight + 150 : 135)
                        Color.clear.frame(height: 1).id("chat-bottom")
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: Chat.shared.responseMessage.last?.text) { _, _ in
                        Task { @MainActor in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("chat-bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            
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
                                    Label("GPT-5.4 mini", image: "openaiLogo")  //TODO: explain that its faster
                                        .font(.system(size: 5))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                //                                Button {
                                //
                                //                                } label: {
                                //                                    Label("GPT-5.4", image: "")      //TODO: explain that its more detailed, will add support for this model later
                                //                                }
                                
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmDark)
                                    .padding()
                            }
                            Button {
                                isNewChat = true
                                Chat.shared.responseMessage.removeAll()
                                
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
                
                
                if !isEmptyStateSeen && Chat.shared.responseMessage.isEmpty {
                    VStack(spacing: 20) {
                        VStack(spacing: 5) {
                            
                            Text("Turn notes, PDFs, and AI chats into spaced repetition flashcards.").font(.headline)
                                .font(.system(size: 20, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineSpacing(1)
                                .foregroundStyle(Color.mmDark)
                                .padding(.horizontal, 32)
                            
                            Text("Rep adapts your content into passive Live Activity memory drills.").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 50)
                        }
                        
                        VStack(spacing: 8) {
                            
                            Text("- Turn this PDF into spaced repetition drills").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .opacity(showEmptyState ? 1 : 0)
                                .offset(y: showEmptyState ? 0 : 8)
                                .animation(.easeOut(duration: 0.45).delay(0.10), value: showEmptyState)
                            
                            Text("- Turn my study notes into quick review prompts").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .opacity(showEmptyState ? 1 : 0)
                                .offset(y: showEmptyState ? 0 : 8)
                                .animation(.easeOut(duration: 0.45).delay(0.20), value: showEmptyState)
                            
                            Text("- Review onboarding documents throughout the day").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .opacity(showEmptyState ? 1 : 0)
                                .offset(y: showEmptyState ? 0 : 8)
                                .animation(.easeOut(duration: 0.45).delay(0.30), value: showEmptyState)
                            
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .opacity(showEmptyState ? 1 : 0)
                    .offset(y: showEmptyState ? 0 : 12)
                    .animation(.easeOut(duration: 0.45), value: showEmptyState)
                    .onAppear {
                        guard !isEmptyStateSeen else { return }
                        
                        withAnimation(.easeOut(duration: 0.45)) {
                            showEmptyState = true
                        }
                    }
                }
                 
                
                Spacer(minLength: 60)
                VStack(alignment: .leading, spacing: 20) {
                    TextField(messagePlaceholder, text: $chatState.chat, axis: .vertical)
                        .focused($isChatFocused)
                        .offset(y: -keyboardHeight)
                        .animation(.easeOut(duration: 0.25), value: isChatFocused)
                        .lineLimit(1...10)
                        .autocorrectionDisabled(false)
                        .padding(.horizontal)
                        .fontWeight(.medium)
                        .onSubmit {
                            showEmptyState = false
                            let photos: [PhotosPickerItem] = selectedPhotos
                            Chat.sendChatMessage(userFile: fileUrls.first, context: context, selectedPhotos: photos)
                            isEmptyStateSeen = true
                            isCircleVisible = true
                            isCirclePulsing = true
                            fileUrls.removeAll()
                            selectedPhotos.removeAll()
                            
                        }.onChange(of: Chat.shared.responseMessage.last?.text) { _, newValue in
                            if let presentText = newValue, !presentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                isCircleVisible = false
                                isCirclePulsing = false
                            }
                        }
                    
                    ForEach(fileUrls, id: \.self) { file in
                        ZStack {
                            Capsule()
                                .frame(maxWidth: .infinity, maxHeight: 28)
                                .glassEffect(.regular)
                            
                            HStack(spacing: 5) {
                                Text(file.lastPathComponent).font(Font.system(size: 12))
                                    .truncationMode(.middle)
                                    .fontWeight(.semibold)
                                    .fontDesign(.rounded)
                                
                                Button {
                                    fileUrls.removeAll(where: { $0 == file })
                                } label: {
                                    Image(systemName: "x.circle.fill").fixedSize()
                                        .foregroundStyle(Color.mmDark)
                                }
                            }.padding(6)
                        }.fixedSize()
                    }.offset(y: -keyboardHeight)
                    
                    PhotoPickerList(selectedPhotos: $selectedPhotos, keyboardHeight: keyboardHeight)
                    
                    HStack(alignment: .bottom) {
                        Menu {
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Upload Photo", systemImage: "photo")
                            }.onChange(of: selectedPhotos) {_, newValueItem in
                                
                                Task { @MainActor in
                                    for item in newValueItem {
                                        let transferPhoto: PhotoTransfer? = try await item.loadTransferable(type: PhotoTransfer.self)
                                        let rawImageData: Data? = transferPhoto?.photo
                                        let _ = UIImage(data: rawImageData ?? Data())
                                    }
                                }
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
                            isEmptyStateSeen = true
                            isCircleVisible = true
                            isCirclePulsing = true
                            
                            let photos: [PhotosPickerItem] = selectedPhotos
                            Chat.sendChatMessage(userFile: fileUrls.first, context: context, selectedPhotos: photos)
                            fileUrls.removeAll()
                            selectedPhotos.removeAll()
                        } label: {
                            ZStack {
                                Circle().fill(Color.mmDark)
                                    .frame(maxWidth: 30, maxHeight: 30)
                                
                                Image(systemName: "arrow.up").foregroundStyle(Color.checkmark)
                                
                            }
                        }.padding(.trailing)
                        
                    }.offset(y: -keyboardHeight)
                }.padding(.leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.clear).glassEffect(.regular, in: .rect(cornerRadius: 30))
                        .offset(y: -keyboardHeight)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal))
                    .padding(.bottom)
                
            }
        }.sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedPhotos: $selectedPhotos)
            
        }
        .sheet(isPresented: $showFilePicker) {
            DocPicker(contentType: [.item, .folder], allowMultipleFileSelect: true) { url in
                fileUrls = url
                
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            
            if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height + 5
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
}


struct MainMenuDataSourceList: View {         ///conditionally renders the list in ImportedNotes.swift based on data source. notion, openai etc
    @Environment(\.modelContext) var context
    @Binding var tabSlideOver: Bool
    @Binding var deleteMultipleTabs: Set<String>
    @State private var selectedCheckBox = false
    
    let title: CombinedDataSource
    var body: some View {
        
        switch title {
        case .notionContent(let pageTitle):
            if tabSlideOver {
                Button {
                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                    if deleteMultipleTabs.contains(pageTitle.pageID) {
                        deleteMultipleTabs.remove(pageTitle.pageID)
                    } else {
                        deleteMultipleTabs.insert(pageTitle.pageID)
                    }
                    
                } label: {
                    TabSelectionCircle(selectedTab: deleteMultipleTabs.contains(pageTitle.pageID))
                }
            }
            
            if !pageTitle.text.isEmpty {
                NavigationLink {
                    ImportedNotes(pageID: pageTitle.pageID, titleSource: title)
                        .navigationBarBackButtonHidden(true)
                    
                } label: {
                    MainMenuTab(userPageTitle: pageTitle, openaiChatTitle: nil, dataSource: title)
                }
                .allowsHitTesting(!tabSlideOver)
            }
            
        case .openaiChatContent(let chatTitle):
            if tabSlideOver {
                Button {
                    print("ALL PAGE IDs: \(deleteMultipleTabs)")
                    if deleteMultipleTabs.contains(chatTitle.openaiId) {
                        deleteMultipleTabs.remove(chatTitle.openaiId)
                    } else {
                        deleteMultipleTabs.insert(chatTitle.openaiId)
                    }
                    
                } label: {
                    TabSelectionCircle(selectedTab: deleteMultipleTabs.contains(chatTitle.openaiId))
                }
            }
            
            if !chatTitle.content.isEmpty {
                NavigationLink {
                    ImportedNotes(pageID: chatTitle.content, titleSource: title)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    MainMenuTab(userPageTitle: nil, openaiChatTitle: chatTitle, dataSource: title)
                }.allowsHitTesting(!tabSlideOver)
            }
        }
    }
}


    struct VoiceTranscriptionView: View {
        @Environment(\.dismiss) var closeAudioTranscriptionSheet
        @Environment(\.modelContext) private var context
        @State private var streamingText: String = ""
        @State private var dynamicBoxHieght: CGFloat = 0
        private var transcriptionPlaceholder: String = "Transcript will turn into Live Activity\n powered review notes."
        
        
        private var transcriptionBoxHeight: CGFloat {
            let verticalPadding: CGFloat = 50
            let minHeight: CGFloat = 50
            let maxHeight: CGFloat = 270
            
            guard !audioManager.liveTranscription.isEmpty else { return minHeight }
            return min(max(dynamicBoxHieght, verticalPadding + minHeight), maxHeight)
        }
        
        private struct HeightPreferenceKey: PreferenceKey {
            static var defaultValue: CGFloat = 0

            static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
                value = nextValue()
            }
        }
        
        
        struct TranscriptionView: View {
            @State private var isCaretVisible = true
            let transcription: String
            
            var transcriptionText: Text {
                Text("\(transcription)\(Text(isCaretVisible ? "|" : " ").foregroundColor(.intervalBlue))")
            }
            
            var body: some View {
                transcriptionText
                    .foregroundStyle(Color.mmDark)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .kerning(-0.5)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .padding(.top)
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
                        }
                    }
                
            }
        }
       
        @ObservedObject private var audioManager = AudioTranscriptionManager.shared
        
        var body: some View {
            VStack {
                
                HStack(alignment: .top) {
                    Button {
                        withAnimation { closeAudioTranscriptionSheet() }
                    } label: {
                        ZStack {
                            Circle().fill(Color.clear).glassEffect(.regular)
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.mmDark)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Spacer().frame(height: 25)
                    
                }.frame(maxWidth: .infinity)
                    .padding(.leading)
                    .padding(.top)
                
                VStack {
                    let shape = RoundedRectangle(cornerRadius: 15)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15).fill(Color.clear).glassEffect(.regular, in: .rect(cornerRadius: 15))
                            
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading) {
                                    
                                    if !audioManager.isTranscribing {
                                        HStack {
                                            Text(transcriptionPlaceholder).padding(.top, 10)
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                 Spacer(minLength: 30)
                                        }
                                    }
                                    
                                    if audioManager.isTranscribing {
                                        TranscriptionView(transcription: audioManager.liveTranscription)
                                            .animation(.easeOut(duration: 0.10), value: audioManager.liveTranscription)
                                            Spacer(minLength: 10)
                                        
                                    }
                                }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .onChange(of: audioManager.liveTranscription) { _,_ in
                                        proxy.scrollTo("typing-caret", anchor: .bottom)
                                    }
                                
                                Color.clear.frame(height: 1).id("typing-caret")  ///invisible anchor for scroll view to go to
                                
                            }.scrollDisabled(audioManager.liveTranscription.isEmpty)
                        }
                        
                        
                        LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.02),
                                                                  .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                                  .init(color: Color.mmBackground.opacity(0.50), location: 0.05),
                                                                  .init(color: Color.mmBackground.opacity(0.30), location: 0.10),]), startPoint: .top, endPoint: .bottom)
                        .frame(maxWidth: .infinity, maxHeight: transcriptionBoxHeight).clipShape(shape)
                        .allowsHitTesting(false)
                        
                        
                        LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.00),
                                                                  .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                                  .init(color: Color.mmBackground.opacity(0.50), location: 0.10),
                                                                  .init(color: Color.mmBackground.opacity(0.30), location: 0.15),]), startPoint: .bottom, endPoint: .top)
                        .frame(maxWidth: .infinity, maxHeight: transcriptionBoxHeight).clipShape(shape)
                        .allowsHitTesting(false)

                    }.frame(minHeight: 50, maxHeight: transcriptionBoxHeight)
                     .onPreferenceChange(HeightPreferenceKey.self) { height in
                            dynamicBoxHieght = height
                        }
                        .animation(.easeOut(duration: 0.5), value: transcriptionBoxHeight)
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    //TODO: tweak audio wave UI, increase wave height sensativity
          
                    Spacer(minLength: 15)
                    HStack(spacing: 3) {
                        ForEach(0..<5) { wave in
                            Capsule().frame(width: 40, height: AudioTranscriptionHelper.waveHeight(for: wave, level: audioManager.audioLevels))
                                .foregroundStyle(Color.mmDark)
                                .animation(.spring(response: 0.18, dampingFraction: 0.72), value: audioManager.audioLevels)
                        }
                    }.padding()
                
                Spacer().frame(height: 5)
                
                Button {
                    audioManager.isTranscribing.toggle()
                  
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.prepare()
                        impact.impactOccurred()
                        
                        if audioManager.isTranscribing {
                            try await allowAudioInputAV()
                            let session = try await audioManager.openAudioSession()
                            try await audioManager.startAudioStream(session: session)
                        } else {
                            try await audioManager.stopAudioStream(context: context) { delta in
                            streamingText += delta
                            }
                            audioManager.liveTranscription.removeAll()
                            
                        }
                    }
                    
                } label: {
                    ZStack {
                        Circle().fill(Color.clear).glassEffect(.regular)
                            .frame(maxWidth: 80, maxHeight: 80)
                            .animation(.spring(response: 0.8, dampingFraction: 0.78), value: audioManager.isTranscribing)
                        
                        if audioManager.isTranscribing {
                            RoundedRectangle(cornerRadius: 12).fill(Color.red).frame(maxWidth: 45, maxHeight: 45)
                                .animation(.spring(response: 0.8, dampingFraction: 0.78), value: audioManager.isTranscribing)
                            
                        } else {
                            Circle().fill(Color.red).frame(maxWidth: 70, maxHeight: 70)
                        }
                    }
                }.padding(.top)
                
                Spacer().frame(height: 150)
                
            }.padding(.top)
                .frame(maxHeight: .infinity)
              
        }.background(Color.mmBackground)
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

#Preview {
    VoiceTranscriptionView()
}
