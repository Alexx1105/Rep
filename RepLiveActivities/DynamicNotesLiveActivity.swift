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


struct AppLogo: View {
    var body: some View {
        
        Image("appicon")
            .resizable()
            .scaledToFit()
        
    }
}


struct DynamicRepLiveActivity: Widget {
    
    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
        case userContentPage
    }
    
    var body: some WidgetConfiguration {
        
        ActivityConfiguration(for: DynamicRepAttributes.self) { context in
            VStack(alignment: .leading, spacing: 5) {
                ZStack {
                    HStack {
                        Text(context.state.plainText)
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                            .frame(maxWidth: 130)
                            .fontWeight(.regular)
                            .lineLimit(1)
                            .font(.system(size: 14)).fontDesign(.rounded)
                            .foregroundStyle(Color.intervalBlue)
                            .background(Capsule().foregroundStyle(Color.intervalBlue).opacity(0.2))
                            .padding(.top)
                        
                        if let url = context.attributes.notesSettingsURL {
                            Link(destination: url) {
                                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .foregroundStyle(Color.mmBackground)
                                    .frame(width: 52, height: 35)
                                    .background {
                                        Capsule().foregroundStyle(Color.kimchilabs.opacity(0.8))
                                    }
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open this page’s note settings")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top)
                            .padding(.trailing)
                            
                        }
                    }.padding(.bottom, 5)
                }.padding(.leading)
                    .zIndex(1)
                
                HStack {
                    ZStack {
                        let contentArray: [String] = context.state.userContentPage
                        let array = contentArray.compactMap { $0 }
                        let content = array.joined(separator: "\n")
                        Text(content)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .fontWeight(.regular)
                            .font(.system(size: 14)).fontDesign(.rounded)
                            .lineSpacing(2)
                            .lineLimit(5)
                            .minimumScaleFactor(0.9)
                            .padding(.vertical, 2)
                        
                    }
                }.padding(.horizontal)
                    .padding(.top, 3)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .background {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [.clear, Color.mmBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 18)
                            Color.mmBackground
                        }
                        .padding(.top, -14)
                    }.zIndex(0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(alignment: .top) {
                        Text(context.state.plainText)
                            .minimumScaleFactor(0.9)
                            .lineLimit(1)
                            .fontWeight(.medium)
                            .font(.system(size: 14)).fontDesign(.rounded)
                            .foregroundStyle(Color.intervalBlue)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .background(Capsule().foregroundStyle(Color.intervalBlue).opacity(0.2))
                        
                    }.frame(alignment: .leading)
                        .padding(.leading, 22)
                }
                
                DynamicIslandExpandedRegion(.center) {}    ///Empty for now
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        if let url = context.attributes.notesSettingsURL {
                            Link(destination: url) {
                                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .foregroundStyle(Color.mmBackground)
                                    .frame(width: 52, height: 30)
                                    .background {
                                        Capsule().foregroundStyle(Color.kimchilabs.opacity(0.8))
                                    }
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open this page’s note settings")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                            .padding(.leading, 52)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Color.mmBackground).opacity(0.8)
                        
                        let contentArray: [String] = context.state.userContentPage
                        let array = contentArray.compactMap { $0 }
                        let content = array.joined(separator: "\n")
                        Text(content)
                            .fontWeight(.regular)
                            .font(.system(size: 14)).fontDesign(.rounded)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.9)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(5)
                            .padding(.horizontal, 5)
                            .padding(.leading, 20)
                            .padding(.trailing)
                            .padding(.vertical, 3)
                            .padding(.bottom)
                    }
                }
            } compactLeading: {
                AppLogo()
            } compactTrailing: {
                HStack {
                    ZStack {
                        Capsule()
                            .foregroundStyle(Color.intervalBlue)
                            .opacity(0.3)
                        
                        Text(context.state.plainText)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.intervalBlue)
                            .minimumScaleFactor(0.9)
                            .padding(.horizontal, 5)
                            .lineLimit(1)
                    }
                }
                
            } minimal: {}
                .keylineTint(Color.white)
                .contentMargins([.leading, .trailing, .bottom], 0, for: .expanded)
        }
    }
}


extension DynamicRepAttributes {
    fileprivate static var preview: DynamicRepAttributes {
        DynamicRepAttributes(activityID: "preview-page-0-0-1")
        
    }
}

extension DynamicRepAttributes.ContentState {
    fileprivate static var titleName: DynamicRepAttributes.ContentState {
        DynamicRepAttributes.ContentState(
            plainText: "Biology review",
            userContentPage: [
                "Photosynthesis converts light energy into chemical energy stored in glucose."
            ]
        )
    }
    
    fileprivate static var contentBody: DynamicRepAttributes.ContentState {
        DynamicRepAttributes.ContentState(
            plainText: "Biology review",
            userContentPage: [
                "Chlorophyll absorbs mostly red and blue wavelengths.",
                "Light-dependent reactions produce ATP and NADPH.",
                "The Calvin cycle uses them to build glucose",
                "Light-dependent reactions produce ATP and NADPH.",
            ]
        )
    }
}

#Preview("Lock Screen", as: .content, using: DynamicRepAttributes.preview) {
    DynamicRepLiveActivity()
} contentStates: {
    DynamicRepAttributes.ContentState.titleName
    DynamicRepAttributes.ContentState.contentBody
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: DynamicRepAttributes.preview) {
    DynamicRepLiveActivity()
} contentStates: {
    DynamicRepAttributes.ContentState.titleName
    DynamicRepAttributes.ContentState.contentBody
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: DynamicRepAttributes.preview) {
    DynamicRepLiveActivity()
} contentStates: {
    DynamicRepAttributes.ContentState.titleName
    DynamicRepAttributes.ContentState.contentBody
}
