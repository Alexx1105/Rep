//
//  PaymentStore.swift
//  Rep
//
//  Created by alex haidar on 12/3/25.
//

#if DEBUG
    let certificate = "StoreKitTestCertificate"
#else
    let certificate = "AppleIncRootCertificate"
#endif

import Foundation
import StoreKit



//struct productAttributes {
//    let displayName: String
//    let description: String
//    let price: String
//    let monthlySubscriptionPeriod: Product.SubscriptionPeriod.Unit?
//    let monthlySubscrioptionValue: Int?
//}

@MainActor
final class PaymentStore {
    
 
    var transactionUpdates: Task<Void, Never>? = nil
    
    init() {
      transactionUpdates = observeTransactions()
    }
    
    deinit { transactionUpdates?.cancel() }
    

    private func observeTransactions() -> Task<Void, Never> {
        
        Task {
            for await i in Transaction.updates {
                self.handleAllTransactions(_: i)
               
            }
        }
    }
    
    private func handleAllTransactions(_ verifyTransactions: VerificationResult<Transaction>) -> Task<Void, Never> {
        
        return Task {
            guard let transaction = verifyTransactions.deviceVerification.first else { return }
        }
        
    }
    
    func runPaymentFlow() async throws {
        
        do {
            let proTier = ["kimchilabs.pro"]                                /// more tiers can be added in future
            let fetchProTier = try await Product.products(for: proTier)
            
            guard let firstProduct = fetchProTier.first else { return }
            
            let token = UUID()
            let result = try await firstProduct.purchase(options: [.appAccountToken(token)])
            //To-Do: add switch case for purchase success/failure
            
            guard let entitled = await firstProduct.currentEntitlement else { return }     ///handle user entitlemnt access later
            
            
            print("proTier fetched: \(fetchProTier)")
            print("purchase initiated, token generated: \(result)")
        } catch {
            print("error fetching products: \(StoreKitError.self as Any)")
            print("purchase erorr: \(Product.PurchaseError.self as Any)")
        }
    }
}
