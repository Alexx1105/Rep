//
//  LiquidGlassTab.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/14/25.

///Store all SwiftUI struct components here from now on

import SwiftUI


struct RootTabs: View {
    
    var body: some View {
        NavigationStack {
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
        }
    }
}

struct TabSelectionCircle: View {
    var selectedTab: Bool
    var body: some View {
        Circle()
            .fill(selectedTab ? Color.blue.opacity(0.7) : Color.mmBackground)
            .stroke(selectedTab ?  Color.blue : Color.gray, lineWidth: 0.5)
            .frame(width: 27, height: 27)
            .transition(.move(edge: .trailing).combined(with: .slide))
            .padding(.leading, 1)
            .overlay { Image(systemName: "checkmark").foregroundStyle(Color.checkmark)}
    }
}

struct MainMenuTab: View {
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    let emoji: String?
    let title: String?
    let pageID: String
    
    var body: some View {
        
        ZStack(alignment: .center) {
            Rectangle()
                .fill(.white.opacity(elementOpacityDark))
                .stroke(Color.mmBackground, lineWidth: 0.2)
                .foregroundStyle(Color.mmDark)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDark, lineWidth: 0.2))
                .opacity(0.8)
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                
                Menu {
                    Text("DynamicRep Settings")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                        .opacity(0.5)
                    
                    NavigationLink(destination: DynamicRepControlsView(pageID: pageID)) {
                        Label("Live activities", systemImage: "clock.badge")
                    }
                    
                } label: {
                    
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(Color.mmDark)
                        .opacity(0.8)
                        .frame(width: 35, height: 35)
                        .padding(5)
                }
                
                HStack(alignment: .center) {
                    
                    if emoji != nil || title != nil {
                        Text(String("\(emoji ?? "")"))
                        Text(String("\(title ?? "")"))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                    } else {
                        Rectangle()
                            .cornerRadius(5)
                            .frame(width: 150, height: 20)
                            .opacity(0.1)
                    }
                }
                .frame(alignment: .leading)
                
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
                Rectangle().foregroundStyle(Color.mmBackground)        ///solid overlay here
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
                    
                    RoundedRectangle(cornerRadius: 25).frame(width: 135, height: 260)
                        .foregroundStyle(Color.intervalBlue).opacity(0.2)
                        .frame(maxWidth: 325, alignment: .trailing)
                        .frame(maxHeight: 420, alignment: .bottom)
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 80) {
                            Text("• Unlimited plain text support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Unlimited plain text support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        HStack(spacing: 110) {
                            Text("• Unlimited LiveActivity flashcards").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Unlimited LiveActivity flashcards").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        HStack(spacing: 98) {
                            Text("• Hyper mode support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Hyper mode support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
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
                .glassEffect(.clear, in: .rect(cornerRadius: 35))         ///glass background here
                
        }
    }
}

#Preview {
    MainMenuTab(emoji: "emoji", title: "title", pageID: "pageID") ///page tab
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

#Preview {
    PaymentMenuCard(isPresented:  .constant(true))
}
