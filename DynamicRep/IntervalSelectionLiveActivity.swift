//
//  IntervalSelectionLiveActivity.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/16/25.
//

import ActivityKit
import WidgetKit
import KimchiKit
import SwiftUI


struct IntervalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IntervalLiveActivityAttributes.self) { context in
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 3) {
                        
                        let intervalTitle: String = context.state.plainText
                        let truncatedTitle = intervalTitle.count > 18 ? String(intervalTitle.prefix(18)) + "…" : intervalTitle
                        
                        Text("\(String(describing: truncatedTitle))")
                            .fontWeight(.regular)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gray)
                        
                      
                        
                        Text("You’ll get flashcards every")
                            .fontWeight(.regular)
                            .font(.system(size: 14))
                        
                    }.padding(.bottom, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    
                    VStack(alignment: .center) {
                        
                        Spacer()
                        Rectangle()
                            .frame(width: 67.5, height: 47.5)
                            .foregroundStyle(Color.intervalBlue).opacity(0.2)
                            .clipShape(RoundedRectangle(cornerRadius: 17.5))
                        
                            .overlay {
                                let intervalNumberSelected: String = context.state.selectedInterval
                                Text("\(String(describing: intervalNumberSelected))").font(Font.system(size: 14))
                                    .fontWeight(.regular)
                                    .foregroundStyle(Color.intervalBlue)
                                
                            }
                    }
                }
            } compactLeading: {
                
                Text("Frequency")
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                
            } compactTrailing: {
                
                VStack() {
                    Rectangle()
                        .frame(width: 45.75, height: 24.75)
                        .foregroundStyle(Color.intervalBlue).opacity(0.2)
                        .clipShape(RoundedRectangle(cornerRadius: 8.75))
                    
                        .overlay {
                            let intervalNumberSelected: String = context.state.selectedInterval
                            Text("\(String(describing: intervalNumberSelected))").font(Font.system(size: 14))
                                .fontWeight(.regular)
                                .foregroundStyle(Color.intervalBlue)
                            
                        }
                }
                
            } minimal: {
                
            }.keylineTint(Color.blue)
        }
    }
}



//extension IntervalLiveActivityAttributes {
//    fileprivate static var preview: IntervalLiveActivityAttributes {
//        IntervalLiveActivityAttributes()
//
//    }
//}
//
//extension IntervalLiveActivityAttributes.ContentState {
//    fileprivate static var titleInterval: IntervalLiveActivityAttributes.ContentState {
//        IntervalLiveActivityAttributes.ContentState(plainText: "")
//
//    }
//}
//
//#Preview("Notification", as: .content, using: IntervalLiveActivityAttributes.preview) {
//    IntervalLiveActivity()
//} contentStates: {
//    IntervalLiveActivityAttributes.ContentState.titleInterval
//}
//
//

