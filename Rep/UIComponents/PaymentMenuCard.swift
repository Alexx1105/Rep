import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct PaymentMenuCard: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var paymentStore: PaymentStore
    var body: some View {
        
        
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                Text("Unlock More With Pro").foregroundStyle(Color.mmDark)
                    .font(.system(size: 20))
                    .frame(maxWidth: 290, alignment: .leading)
                    .fontWeight(.semibold)
                
                
                Button("close") {
                    
                    withAnimation {
                        isPresented = false
                    }
                    
                }.buttonStyle(.glass)
                
            }.padding(.top)
            
            
            ZStack {
                Rectangle().foregroundStyle(Color.mmBackground).ignoresSafeArea()        ///solid overlay here
                    .frame(maxWidth: .infinity, maxHeight: 700)
                    .cornerRadius(25)
                    .padding()
                
                HStack(alignment: .top, spacing: 108) {
                    
                    VStack(spacing: 18) {
                        Text("Basic").foregroundStyle(Color.mmDark)
                            .fontWeight(.medium)
                            .font(.system(size: 20))
                        
                        HStack(spacing: 2) {
                            Text("$0").foregroundStyle(Color.mmDark)
                                .fontWeight(.black)
                                .font(.system(size: 32))
                            
                            Text("/mo").foregroundStyle(Color.mmDark)
                                .fontWeight(.medium)
                                .offset(y: 2)
                                .opacity(0.50)
                        }
                    }
                    
                    
                    VStack(spacing: 18) {
                        Text("Pro").foregroundStyle(Color.intervalBlue)
                            .font(.system(size: 20))
                            .fontWeight(.heavy)
                            .overlay {
                                Capsule().foregroundStyle(Color.intervalBlue.opacity(0.2))
                                    .frame(width: 52, height: 25)
                            }
                        
                        HStack(spacing: 2) {
                            Text("$8").foregroundStyle(Color.mmDark)
                                .fontWeight(.black)
                                .font(.system(size: 32))
                            
                            Text("/mo").foregroundStyle(Color.mmDark)
                                .fontWeight(.medium)
                                .offset(y: 2)
                                .opacity(0.50)
                        }
                    }
                }.frame(maxHeight: 630, alignment: .top)
                
                ZStack {
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 80) {
                            Text("• Unlimited plain text support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Unlimited plain text support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        HStack(spacing: 110) {
                            Text("• Unlimited LiveActivity flashcards").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Unlimited LiveActivity flashcards").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        HStack(spacing: 102) {
                            Text("• basic mode support").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Hyper mode support").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 280, alignment: .leading)
                        
                        
                        HStack(spacing: 73) {
                            Text("• Import up to two pages at a time").font(.system(size: 12)).fontWeight(.medium).opacity(0.50)
                            Text("• Emoji support 😄").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 313, alignment: .trailing)
                        
                        HStack(spacing: 98) {
                            Text("• first access to\nfuture supported\nnotion content\ntypes").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 300, alignment: .trailing)
                        
                        HStack(spacing: 98) {
                            Text("• Unlimited # of\nimported pages\nat a time").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 280, alignment: .trailing)
                        
                        HStack(spacing: 98) {
                            Text("• Imported notes\nauto-fetch latest\nchanges made\nin Notion").font(.system(size: 12)).fontWeight(.heavy).foregroundStyle(Color.intervalBlue)
                            
                        }.frame(maxWidth: 295, alignment: .trailing)
                    }
                }
                
                
                
                VStack {
                    HStack(alignment: .top) {
                        Divider().frame(maxHeight: 580)
                    }
                    
                    
                    
                    Button {
                            Task {
                                try await paymentStore.runPaymentFlow()
                            }
                        } label: {
                        RoundedRectangle(cornerRadius: 30).glassEffect()
                            .frame(maxWidth: 350, maxHeight: 48)
                            .foregroundStyle(Color.intervalBlue)
                        
                        
                            .overlay {
                                Text("Coming Soon").foregroundStyle(Color.kimchiLabs)  //change back to "Upgrade" later
                                    .fontWeight(.heavy)
                                
                            }.padding(.bottom)
                    }.disabled(true)   //dont forgot to remove
                }.padding(.top, 5)
                
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 800)
        .background {
            Rectangle()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: 800)
                .glassEffect(.regular, in: .rect(cornerRadius: 35))         ///glass background here
            
        }
    }
}

#Preview {
    PaymentMenuCard(isPresented: .constant(true))
        .environmentObject(PaymentStore())
}
