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
                Tab("Menu", image: "menuButton") {
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
    let showEmoji: String?
    let showTitle: String?
    
    
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
                    
                    NavigationLink(destination: DynamicRepControlsView(storeSelectedOption: 0)) {
                        Label("Live activities", systemImage: "clock.badge")
                    }
                    
                    
                    
                } label: {
                    
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(Color.mmDark)
                        .opacity(0.8)
                        .frame(width: 35, height: 35)
                        .padding(5)
                }
                
                if showEmoji != nil || showTitle != nil {
                    Text(String("\(showEmoji ?? "")"))
                    Text(String("\(showTitle ?? "")"))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.mmDark)
                } else {
                    Rectangle()
                        .cornerRadius(5)
                        .frame(width: 150, height: 20)
                        .opacity(0.1)
                    
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
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    MainMenuTab(showEmoji: "", showTitle: "") ///page tab
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
