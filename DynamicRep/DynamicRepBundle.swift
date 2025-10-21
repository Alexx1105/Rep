//
//  DynamicRepBundle.swift
//  DynamicRep
//
//  Created by alex haidar on 3/26/25.
//

import WidgetKit
import SwiftUI
import ActivityKit
import KimchiKit
import OSLog


@main
struct DynamicRepBundle: WidgetBundle {
    init() {
        if #available(iOS 17.0, *) {
            Logger().log("attributes-type: \(String(reflecting: DynamicRepAttributes.self))")
        } else {
            print("activity not running")
        }
    }
    var body: some Widget {
        DynamicRepLiveActivity()
        IntervalLiveActivity()
    }
}





