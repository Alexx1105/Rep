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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweepProgress: CGFloat = 0

    var body: some View {
        let label = Text(text)
            .fontDesign(.rounded)
            .fontWeight(.medium)

        label
            .foregroundStyle(Color.mmDark)
            .opacity(reduceMotion ? 1 : 0.55)
            .overlay {
                if !reduceMotion {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let bandWidth = width * 0.65

                        LinearGradient(
                            stops: [
                                .init(color: Color.mmDark.opacity(0), location: 0),
                                .init(color: Color.mmDark.opacity(0.18), location: 0.24),
                                .init(color: Color.mmDark.opacity(0.7), location: 0.5),
                                .init(color: Color.mmDark.opacity(0.18), location: 0.76),
                                .init(color: Color.mmDark.opacity(0), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: bandWidth)
                        .offset(x: sweepProgress * (width + bandWidth) - bandWidth)
                    }
                    .mask { label }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .onAppear {
                sweepProgress = 0
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    sweepProgress = 1
                }
            }
    }
}

#Preview("Shimmer Text · Light") {
    ShimmerText(text: "Generating notes ...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
}

#Preview("Shimmer Text · Dark") {
    ShimmerText(text: "Generating notes ...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
}
