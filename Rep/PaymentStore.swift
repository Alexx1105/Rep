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



final class PaymentStore: ObservableObject {
    
    @Published var isProTier: Bool = false
    var transactionUpdates: Task<Void, Never>? = nil
    
    @MainActor
    init() {
      transactionUpdates = observeTransactions()
    }
    
    deinit { transactionUpdates?.cancel() }
    
    
    @MainActor
    func updateProMode(isProTier: Bool) {
        self.isProTier = isProTier
        UserDefaults.standard.set(isProTier, forKey: "isProTier")
    }
    
    
    private func observeTransactions() -> Task<Void, Never> {
        
        return Task.detached {
            for await transactionUpdate in Transaction.updates {
                
                do {
                    try await self.handleTransactionVerify(transactionUpdate)
                    print("current transactions: \(transactionUpdate)")
                    
                } catch {
                    print("transaction event listener error ❗️: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleTransactionVerify(_ verifyTransactions: VerificationResult<Transaction>) async throws {
        
        let transaction = try verifyTransactions.payloadValue
        
        if transaction.revocationDate == nil {
            await updateProMode(isProTier: true)
        } else {
            await updateProMode(isProTier: false)
        }
        await transaction.finish()
    }
    
    @MainActor
    func runPaymentFlow() async throws {
        
        do {
            let proTier = ["kimchilabs.pro"]                                /// more tiers can be added in future
            let fetchProTier = try await Product.products(for: proTier)
            
            guard let firstProduct = fetchProTier.first else { return }
            
            let token = UUID()
            let result = try await firstProduct.purchase(options: [.appAccountToken(token)])
            
            switch result {
            case .success(let verify):
                try await handleTransactionVerify(verify)
                print("purchase success!")
            case .pending:
                //To-Do
                print("transaction is pending...")
            case .userCancelled:
                //To-Do
                print("user cancelled transaction")
            default:
                print("unknown error")
            }
            
            let entitled = firstProduct.currentEntitlements
        
            print("entitlemnt fetched ✅: \(entitled)", "proTier fetched ✅: \(fetchProTier)", "purchase initiated, token generated ✅: \(result)")
        } catch {
            print("error fetching products: \(StoreKitError.self as Any)", "purchase erorr: \(Product.PurchaseError.self as Any)")
        }
    }
}
