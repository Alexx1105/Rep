//
//  UpgradePlanAlertSheet.swift
//  Rep
//
//  Created by alex haidar on 8/29/26.
//
import Foundation
import SwiftUI



struct UpgradePlanAlertSheet: View {
    @Binding var isPresented: Bool
    @State var isAnimating: Bool = false
    let onDismiss: () -> Void
    
    var body: some View {
        VStack{}.frame(width: 0, height: 0)
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 30).fill(Color.clear)
                        .glassEffect(.regular, in: .rect(cornerRadius: 30))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                    
                    VStack(alignment: .center, spacing: 10) {
                        
                        HStack(alignment: .top) {
                            Capsule().frame(width: 50, height: 5)
                        }.padding(.top)
                        
                        Spacer()
                        
                        Text("Out of AI Credits")
                            .font(.system(size: 23)).font(.headline).fontWeight(.bold)
                            .foregroundStyle(Color.mmDark)
                            .animation(.easeOut(duration: 0.45).delay(0.30), value: isAnimating)
                        
                        Text("Go to settings → Upgrade Plan")
                            .font(.system(size: 16)).font(.subheadline).fontWeight(.regular)
                            .foregroundStyle(Color.mmDark).opacity(0.8)
                            .animation(.easeOut(duration: 0.45).delay(0.30), value: isAnimating)
                        
                        Spacer()
                    }
                }
            }.onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    isAnimating = true
                }
            }
    }
}



#Preview {
    UpgradePlanAlertSheet(isPresented: .constant(true), onDismiss: {})
}
