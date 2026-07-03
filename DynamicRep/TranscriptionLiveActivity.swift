//
//  TranscriptionLiveActivity.swift
//  Rep
//
//  Created by alex haidar on 6/27/26.
//
import ActivityKit
import WidgetKit
import KimchiKit
import SwiftUI



struct LiveActivityWaveformExpanded: View {
    let audioLevel: Double
    let isRecording: Bool
    let isPaused: Bool
    
    private let phases: [Double] = [0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65, 0.18]
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.15, paused: !isRecording || isPaused || audioLevel <= 0.03)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isActive = isRecording && !isPaused && audioLevel > 0.03
            let curve = isActive ? 0.85 : 0.0

            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<9, id: \.self) { index in
                    let phase = phases[index]
                    let sine = sin((time * 4.8) + (phase * .pi * 2))
                    let normalized = (sine + 1) / 2
                    let idleHeight = 21.0
                    let height = isActive ? idleHeight + normalized * 24.0 * curve : idleHeight

                    Capsule()
                        .frame(width: 10, height: height)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(height: 42, alignment: .center)
        }
    }
}

struct LiveActivityWaveformMinimal: View {
    let audioLevel: Double
    let isRecording: Bool
    let isPaused: Bool
    
    
    private let phases: [Double] = [0.15, 0.55, 0.95, 0.35, 0.75]
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.15, paused: !isRecording || isPaused || audioLevel <= 0.03)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isActive = isRecording && !isPaused && audioLevel > 0.03
            let curve = isActive ? 0.85 : 0.0
            
            HStack(alignment: .center, spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    let phase = phases[index]
                    let sine = sin((time * 4.8) + (phase * .pi * 2))
                    let normalized = (sine + 1) / 2
                    let idleHeight = 4.0
                    let height = isActive ? idleHeight + normalized * 24.0 * curve : idleHeight
                    
                    Capsule()
                        .frame(width: 2, height: height)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}


struct TranscriptionLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranscriptionLiveActivityAttributes.self) { context in
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    
                    LiveActivityWaveformExpanded(audioLevel: context.state.audioLevel, isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                    
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .center) {
                        
                        Spacer(minLength: 2)
                        Rectangle()
                            .frame(maxWidth: .infinity, maxHeight: 47.5)
                            .foregroundStyle(Color.red).opacity(0.2)
                            .clipShape(RoundedRectangle(cornerRadius: 17.5))
                            .padding(1)
                        
                        
                            .overlay {
                                HStack {
                                    Spacer(minLength: 10)
                                    Text(context.state.startedAt, style: .timer).font(Font.system(size: 14))
                                        .fontDesign(.monospaced)
                                        .fontWeight(.regular)
                                        .foregroundStyle(Color.red)
                                    
                                }.frame(maxWidth: .infinity)
                                    .padding(.leading)
                                
                            }
                        
                    }.padding(.leading)
                    
                }
                
            } compactLeading: {
                HStack {
                    Image("appicon")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                
            } compactTrailing: {
                HStack(spacing: 1) {
                    LiveActivityWaveformMinimal(audioLevel: context.state.audioLevel, isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                }
                
                
            } minimal: {
                Image(systemName: "microphone.circle").opacity(0.8)
                
            }.keylineTint(Color.white)
        }
    }
}


@available(iOS 18.0, *)
#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: TranscriptionLiveActivityAttributes()) {
    TranscriptionLiveActivity()
} contentStates: {
    TranscriptionLiveActivityAttributes.ContentState(
        isRecording: true,
        isPaused: false,
        audioLevel: 0.0,
        startedAt: Date()
    )
}
