//
//  LiquidGlassTab.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/14/25.

///misc SwiftUI components
import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit



@MainActor
public final class Toast: ObservableObject {
    public static let shared = Toast()
    
    public func callToastOnPageLoad(_ bind: Binding<Bool>) async {
        bind.wrappedValue = true
        
        Task { @MainActor in
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation(.easeInOut(duration: 0.2)) {
                bind.wrappedValue = false
            }
        }
    }
}

struct SoftRevealModifier: ViewModifier {
    let trigger: String
    
    @State private var opacity: Double = 1
    @State private var blur: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var lastTrigger: String = ""
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .blur(radius: blur)
            .offset(y: offsetY)
            .onAppear {
                lastTrigger = trigger
                opacity = 1
                blur = 0
                offsetY = 0
            }
            .onChange(of: trigger) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !trimmed.isEmpty, newValue != lastTrigger else {
                    lastTrigger = newValue
                    return
                }
                
                lastTrigger = newValue
                
                var transaction = Transaction()
                transaction.disablesAnimations = true
                
                withTransaction(transaction) {
                    opacity = 0
                    blur = 8
                    offsetY = 8
                }
                
                withAnimation(.easeOut(duration: 0.32)) {
                    opacity = 1
                    blur = 0
                    offsetY = 0
                }
            }
    }
}

extension View {
    func softReveal(trigger: String) -> some View {
        modifier(SoftRevealModifier(trigger: trigger))
    }
}



