//
//  LaunchScreen.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/28/24.
//

import SwiftUI

struct LaunchScreen: View {
    
    @StateObject var navPath = NavPath.shared
    
    var body: some View {
        
        VStack {
            
            Image("launch")
            
            Text("Kimchi Labs")
                .font(.system(size: 32))
                .fontWeight(.black)
                .tracking(-2)
                .foregroundStyle(.black)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.launch)
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline:.now() + 0.7) {
                navPath.navigate(to: .home)
            }
        }
        
    }
}

#Preview {
    LaunchScreen()
}
