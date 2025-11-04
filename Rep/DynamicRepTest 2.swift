//
//  test.swift
//  MuscleMemory
//
//  Created by alex haidar on 3/10/25.
//
//FOR TESTING/DEBUGGING PURPOSES ONLY

import SwiftUI
import Foundation
import ActivityKit
import KimchiKit


struct Test: View {
    var body: some View {
        
      Button("Start Local Live Activity") {
             debugStartIntervalLiveActivity()
        }
    }
}

#Preview {
    Test()
}
