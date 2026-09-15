/* middleware coordinator that fetches and handles
 the correct product for the payment frontend */
import Foundation
import StoreKit


final class PaymentPricingCoordinator {
    private init() {}
    
    static let shared = PaymentPricingCoordinator()
    
    
    enum PaywallTier: Int, CaseIterable, Identifiable {
        case free
        case pro
        case aiMax
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .free:
                return "Free"
            case .pro:
                return "Pro"
            case .aiMax:
                return "AI Max"
            }
        }
    }
    
    
    enum BillingInterval {
        case monthly
        case annual
    }
    
    
    func fetchProductId(tier: PaywallTier, interval: BillingInterval) -> String? {
        switch (tier, interval) {
        case (.pro, .monthly):
            return "kimchilabs.repapp.pro.monthly"
        case (.pro, .annual):
            return "kimchilabs.repapp.pro.annual"
        case (.aiMax, .monthly):
            return "kimchilabs.repapp.ai_max.monthly"
        case (.aiMax, .annual):
            return "kimchilabs.repapp.ai_max.annual"
        case (.free, _ ):
            return nil
        }
    }
}
