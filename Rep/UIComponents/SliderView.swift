import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

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
