import SwiftUI
import SwiftData

struct PaymentMenuCard: View {
    @Binding var isPresented: Bool
    @Binding var billingPlanTab: PaymentPricingCoordinator.BillingInterval
    @EnvironmentObject var paymentStore: PaymentStore
    @Environment(\.dismiss) var closePaymentSheet
    
    @State private var selectedTier: PaymentPricingCoordinator.PaywallTier = .pro
    
    let coordinator = PaymentPricingCoordinator.shared
    
    private let repFreeFeatures = ["Unlimited Notion page imports",
                                   "3 lifetime AI credits(3 AI generations)",
                                   "60 minutes of audio transcription — one time"]
    
    private let repProFeatures = [
        "250 AI credits every month",
        "Up to 4 hours of audio transcription",
        "Use credits for Rep AI chat, card generation, and audio transcription",
        "Notion Auto Sync access",
        "Credits refresh every billing month"
    ]
    
    private let repAiMaxFeatures = [
        "1,000 AI credits every month",
        "Up to 16 hours of audio transcription",
        "4× the AI credits included with Rep Pro",
        "Use credits for Rep AI chat, card generation, and audio transcription",
        "Credits refresh every billing month"
    ]
    
    private var hasPurchasedSelectedTier: Bool {
        switch (selectedTier, paymentStore.currentPlan) {
        case (.free, .free), (.pro, .pro), (.aiMax, .aiMax):
            return true
        default:
            return false
        }
    }
    
    
    var body: some View {
        VStack {}
            .frame(width: 0, height: 0)
            .sheet(isPresented: $isPresented) {
                VStack(spacing: 20) {
                    
                    if selectedTier.id != .free {
                        Picker("", selection: $billingPlanTab) {
                            Text("Monthly").tag(PaymentPricingCoordinator.BillingInterval.monthly)
                            Text("Annual").tag(PaymentPricingCoordinator.BillingInterval.annual)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    TabView(selection: $selectedTier) {
                        freeTier(title: "Rep Free")
                            .tag(PaymentPricingCoordinator.PaywallTier.free)
                        
                        proPlanPage
                            .tag(PaymentPricingCoordinator.PaywallTier.pro)
                        
                        maxTier(title: "Rep AI Max")
                            .tag(PaymentPricingCoordinator.PaywallTier.aiMax)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .padding(.top)
                .presentationDetents([.fraction(0.7)])
            }
    }
    
    private var tierBreadcrumb: some View {
        HStack(spacing: 16) {
            ForEach(PaymentPricingCoordinator.PaywallTier.allCases) { tier in
                Button {
                    withAnimation(.snappy) {
                        self.selectedTier = tier
                    }
                } label: {
                    VStack(spacing: 7) {
                        Text(tier.title)
                            .font(.subheadline)
                            .fontWeight(self.selectedTier == tier ? .bold : .medium)
                            .foregroundStyle(
                                Color.mmDark.opacity(self.selectedTier == tier ? 1 : 0.4)
                            )
                        
                        Capsule()
                            .fill(
                                self.selectedTier == tier
                                ? Color.mmDark
                                : Color.mmDark.opacity(0.15)
                            )
                            .frame(
                                width: self.selectedTier == tier ? 28 : 8,
                                height: 6
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.snappy, value: self.selectedTier)
    }
    
    
    private func freeTier(title: String) -> some View {
        VStack(spacing: 30) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .foregroundStyle(Color.gray)
                    .opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .padding(.horizontal)
                
                VStack(spacing: 5) {
                    Text("Free")
                        .font(.system(.headline))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.mmDark)
                    
                    HStack(spacing: 5) {
                        Text("$0")
                            .font(.system(size: 36))
                            .fontWeight(.black)
                            .foregroundStyle(Color.mmDark)
                        
                        Text(self.billingPlanTab == .monthly ? "/month" : "/year")
                            .font(.system(size: 24))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                    }
                }
                .padding(.vertical)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Everything included in the free tier")
                    .font(.system(.headline))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.mmDark)
                    .padding(.leading)
                
                ForEach(self.repFreeFeatures, id: \.self) { feature in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                        
                        Text(feature)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 20) {
                tierBreadcrumb
                
                HStack(spacing: 10) {
                    Text("Already Included")
                        .font(.system(.headline))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.intervalBlue)
                    
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.intervalBlue)
                }
            }
        }.padding(.top)
    }
    
    
    private var proPlanPage: some View {
        VStack(spacing: 30) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .foregroundStyle(Color.gray)
                    .opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .padding(.horizontal)
                
                VStack(spacing: 5) {
                    Text("Rep Pro")
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.mmDark)
                    
                    HStack(spacing: 5) {
                        Text(self.billingPlanTab == .monthly ? "$7.99" : "$79.99")
                            .font(.system(size: 36))
                            .fontWeight(.black)
                            .foregroundStyle(Color.mmDark)
                        
                        Text(self.billingPlanTab == .monthly ? "/month" : "/year")
                            .font(.system(size: 24))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                    }
                }
                .padding(.vertical)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Everything included with Rep Pro")
                    .font(.system(.headline))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.mmDark)
                    .padding(.leading)
                
                ForEach(self.repProFeatures, id: \.self) { feature in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                        
                        Text(feature)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .center, spacing: 20) {
                tierBreadcrumb
                
                Button {
                    Task {
                        do {
                            guard let productId = coordinator.fetchProductId(tier: selectedTier, interval: billingPlanTab) else { return }
                            try await paymentStore.runPaymentFlow(productId: productId)
                            isPresented = false
                        } catch {
                            print("failure to run payment flow | Pro tier", ErrorDesc.callsiteError, error)
                        }
                    }
                } label: {
                    Text(hasPurchasedSelectedTier ? "Current Plan" : "Purchase")
                        .font(.system(.headline))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.mmBackground)
                        .frame(maxWidth: .infinity, maxHeight: 45)
                    
                }.buttonStyle(.glassProminent)
                    .tint(Color.mmDark)
                    .padding(.horizontal)
                    .disabled(hasPurchasedSelectedTier)
            }
        }
    }
    
    
    private func maxTier(title: String) -> some View {
        VStack(spacing: 30) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .foregroundStyle(Color.gray)
                    .opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .padding(.horizontal)
                
                VStack(spacing: 5) {
                    Text("Rep AI Max")
                        .font(.system(.headline))
                        .fontWeight(.black)
                        .foregroundStyle(Color.mmDark)
                    
                    HStack(spacing: 5) {
                        Text(self.billingPlanTab == .monthly ? "$19.99" : "$99.99")
                            .font(.system(size: 36))
                            .fontWeight(.black)
                            .foregroundStyle(Color.mmDark)
                        
                        Text(self.billingPlanTab == .monthly ? "/month" : "/year")
                            .font(.system(size: 24))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                    }
                }
                .padding(.vertical)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Everything included with Rep AI Max")
                    .font(.system(.headline))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.mmDark)
                    .padding(.leading)
                
                ForEach(self.repAiMaxFeatures, id: \.self) { feature in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                        
                        Text(feature)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(Color.mmDark)
                            .opacity(0.5)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .center, spacing: 20) {
                tierBreadcrumb
                
                Button {
                    Task {
                        do {
                            guard let productId = coordinator.fetchProductId(tier: selectedTier, interval: billingPlanTab) else { return }
                            try await paymentStore.runPaymentFlow(productId: productId)
                            isPresented = false
                        } catch {
                            print("failed to initiate payment flow | Max tier", ErrorDesc.callsiteError, error)
                        }
                    }
                } label: {
                    ZStack {
                        Capsule()
                            .frame(maxWidth: .infinity, maxHeight: 55)
                            .foregroundStyle(Color.intervalBlue)
                            .glassEffect(.clear)
                            .padding(.horizontal)
                        
                        Text(hasPurchasedSelectedTier ? "Current Plan" : "Purchase")
                            .font(.system(.headline))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.kimchiLabs)
                    }
                }
                .disabled(hasPurchasedSelectedTier)
            }
        }
    }
}




#Preview {
    PaymentMenuCard(isPresented: .constant(true), billingPlanTab: .constant(.monthly))
        .environmentObject(PaymentStore.shared)
}
