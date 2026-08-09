//
//  UIAnimations.swift
//  Rep
//
//  Created by alex haidar on 6/26/26.
//
import SwiftUI
import Foundation



struct ShimmerText: View {
    let text: String
    
    @State private var shineOffset: CGFloat = -1
    
    var body: some View {
        Text(text)
            .opacity(0.35)
            .fontDesign(.rounded)
            .fontWeight(.medium)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.15),
                            .white.opacity(0.95),
                            .white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.75)
                    .offset(x: shineOffset * geo.size.width)
                    .mask(
                        Text(text)
                           
                            
                    )
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) {
                    shineOffset = 1.8
                }
            }
    }
}


