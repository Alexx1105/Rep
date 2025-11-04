//
//  DynamicRepLiveActivity.swift
//  DynamicRep/Users/alexhaidar/Documents/Developer/MuscleMemory/DynamicRepExtension.entitlements
//
//  Created by alex haidar on 3/26/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import KimchiKit

///content state struct exists in the KimchiKit internal package now

struct AppLogo: View {
    var body: some View {
        
        Image("appicon")
            .resizable()
            .scaledToFit()
        
    }
}


struct DynamicRepLiveActivity: Widget {
    var body: some WidgetConfiguration {
        
        ActivityConfiguration(for: DynamicRepAttributes.self) { context in
            // Lock screen/banner UI goes here
            
            VStack(alignment: .leading, spacing: 3) {
                
                VStack(alignment: .leading) {
                   
                    ZStack {
                        Text("from: \(context.state.plainText)")
                            .fontWeight(.medium)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.intervalBlue)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .background(Capsule()
                                .frame(width: .infinity, height: 23)
                                .foregroundStyle(Color.intervalBlue).opacity(0.3)
                                .padding(.top)
                                .padding(.leading, 1))

                    }
                       
                    
                    
                    VStack(alignment: .leading) {
                        let contentArray: [String] = context.state.userContentPage
                        let array = contentArray.compactMap { $0 }
                        let content = array.joined(separator: "\n")
                        Text("\n\(content)")
                            .fontWeight(.semibold)
                            .font(.system(size: 16))
                            .lineSpacing(3)
                            .lineLimit(7)
                            .padding(.leading, 11)
                        
                    }
                    .padding(.trailing, 30)
                }
            }
            
            .padding(.bottom)
            .frame(alignment: .topLeading)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.black)
            
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    
                    HStack() {
                        Text("from:")
                            .fontWeight(.regular)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.gray)
                            .padding(.leading, 7)
                            .padding(.top, 32)
                        
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(context.state.plainText)
                                .fontWeight(.medium)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.intervalBlue)
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .background(Capsule()
                                    .frame(width: .infinity, height: 23)
                                    .foregroundStyle(Color.intervalBlue).opacity(0.3)
                                    .padding(.top)
                                    .padding(.leading, 1))
                            
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {}  ///Empty for now
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            let contentArray: [String] = context.state.userContentPage
                            let array = contentArray.compactMap { $0 }
                            let content = array.joined(separator: "\n")
                            Text("\(content)")
                                .fontWeight(.semibold)
                                .font(.system(size: 16))
                                .padding(.leading, 7)
                            
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } compactLeading: {
                AppLogo()
                
            } compactTrailing: {
                
                HStack {
                    Text(context.state.plainText)
                        .fontWeight(.regular)
                        .foregroundStyle(Color.gray)
                    
                    Spacer()
                }
                
            } minimal: {
                
            }
            .keylineTint(Color.white)
        }
    }
}


extension DynamicRepAttributes {
    fileprivate static var preview: DynamicRepAttributes {
        DynamicRepAttributes(activityID: "")
        
    }
}

extension DynamicRepAttributes.ContentState {
    fileprivate static var titleName: DynamicRepAttributes.ContentState {
        DynamicRepAttributes.ContentState(plainText: "", userContentPage: [])
        
    }
    
    fileprivate static var contentBody: DynamicRepAttributes.ContentState {
        DynamicRepAttributes.ContentState(plainText: "", userContentPage: [])
    }
}

#Preview("Notification", as: .content, using: DynamicRepAttributes.preview) {
    DynamicRepLiveActivity()
} contentStates: {
    DynamicRepAttributes.ContentState.titleName
    DynamicRepAttributes.ContentState.contentBody
}



