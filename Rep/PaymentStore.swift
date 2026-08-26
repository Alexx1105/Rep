//
//  PaymentStore.swift
//  Rep
//
//  Created by alex haidar on 12/3/25.
//
/* Payment store client for observing transactions,
 updating entitlements via rpc, handling payment
 failure cases, loading products, preparing new purchases,
 and fetching products already paid for by user */
import Foundation
import StoreKit
import Supabase
import SwiftUI


@MainActor
final class PaymentStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var entitlement: EntitlementSnapshot?
    @Published private(set) var usage: UsageSnapshot?
    @Published private(set) var state: PaymentState = .idle
    
    let creditBucketsManager = CreditBucketsManager.shared
    static let shared = PaymentStore()
    
    private var appAccountToken: UUID?
    private var transactionUpdates: Task<Void, Never>?
    private var inFlightTransactionIDs: Set<UInt64> = []
    
    let supabase = SupabaseClientManager.shared
    
    var currentPlan: BillingPlan {
        entitlement?.plan ?? .free
    }
    
    var hasPaidAccess: Bool {
        switch currentPlan {
        case .pro, .aiMax:
            return entitlement?.status == .active || entitlement?.status == .grace_period || entitlement?.status == .billing_retry
        case .free:
            return false
        }
    }
    
    
    init() {
        transactionUpdates = observeTransactionUpdates()
    }
    
    deinit {
        transactionUpdates?.cancel()
    }
    
    
    func resetForSignOut() {            //TODO: add a sign out option and call
        self.appAccountToken = nil
        self.products = []
        self.entitlement = nil
        self.usage = nil
        self.inFlightTransactionIDs.removeAll()
        
        self.creditBucketsManager.reset()
        self.state = .idle
    }
    
    
    func refreshCreditsRollover() async throws {
        try await refreshResolvedEntitlement()
        try await creditBucketsManager.refreshBillingCredits(plan: currentPlan)
        
        //TODO: call credit refresh bucket functions here
    }
    
    
    func prepareForAuthenticatedUser() async {
        state = .loading
        
        do {
            async let token = supabase.loadAppAccountToken()
            async let storeProducts = supabase.getBillingProducts()
            let (loadedToken, loadedProducts) = try await (token, storeProducts)
            self.appAccountToken = loadedToken
            self.products = loadedProducts
            
            await processUnfinishedTransactions()
            await processCurrentEntitlements()
            try await refreshResolvedEntitlement()
            try await creditBucketsManager.refreshBillingCredits(plan: self.currentPlan)
            
            state = .ready
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
    
    
    func purchase(_ product: Product) async throws {
        if appAccountToken == nil {
            self.appAccountToken = try await supabase.loadAppAccountToken()
        }
        
        guard let appAccountToken else { throw PaymentStoreError.invalidAppAccountToken }
        
        state = .purchasing(productID: product.id)
        
        do {
            let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])
            
            switch result {
            case .success(let verification):
                _ = try await process(verification, finishAfterSync: true)
                state = .ready
            case .pending:
                state = .pending
            case .userCancelled:
                state = .cancelled
            @unknown default:
                state = .failed(message: "StoreKit returned an unknown purchase result.")
            }
        } catch {
            state = .failed(message: error.localizedDescription)
            throw error
        }
    }
    
    
    func runPaymentFlow(productId: String) async throws {
        if appAccountToken == nil {
            self.appAccountToken = try await supabase.loadAppAccountToken()
        }
        
        if products.isEmpty {
            self.products = try await supabase.getBillingProducts()
        }
        
        guard let product = products.first(where: { $0.id == productId }) else { throw PaymentStoreError.productNotFound(productId) }
        try await self.purchase(product)
    }
    
    
    func restorePurchases() async throws {
        state = .loading
        
        do {
            try await AppStore.sync()
            await processCurrentEntitlements()
            try await refreshResolvedEntitlement()
            state = .ready
        } catch {
            state = .failed(message: error.localizedDescription)
            throw error
        }
    }
    
    
    func processUnfinishedTransactions() async {
        for await verification in Transaction.unfinished {
            do {
                _ = try await process(verification, finishAfterSync: true)
            } catch {
                state = .failed(message: error.localizedDescription)
            }
        }
    }
    
    
    func processCurrentEntitlements() async {
        for await verification in Transaction.currentEntitlements {
            do {
                _ = try await process(verification, finishAfterSync: false)
            } catch {
                state = .failed(message: error.localizedDescription)
            }
        }
    }
    
    
    func refreshResolvedEntitlement() async throws {
        let session = try await supabaseDBClient.auth.session
        let decoder = JSONDecoder()
        
        let response = try await supabaseDBClient.rpc("resolve_current_entitlement", params: ResolveEntitlementParameters(p_user_id: session.user.id)).execute()
        let rows = try decoder.decode([ResolvedEntitlementRow].self, from: response.data)
        
        guard let resolved = rows.first else { throw PaymentStoreError.noAuthenticatedUser }
        entitlement = EntitlementSnapshot(plan: resolved.effective_plan_key, status: resolved.subscription_status, productId: entitlement?.productId,
                                          effectiveFrom: resolved.effective_at, effectiveUntil: resolved.expires_at, willAutoRenew: resolved.auto_renew_enabled,
                                          version: resolved.entitlement_version)
    }
    
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { return }
                
                do {
                    _ = try await self.process(verification, finishAfterSync: true)
                    self.state = .ready
                } catch {
                    self.state = .failed(message: error.localizedDescription)
                }
            }
        }
    }
    
    
    @discardableResult
    private func process(_ verification: VerificationResult<StoreKit.Transaction>, finishAfterSync: Bool) async throws -> PurchaseSyncResponse? {
        switch verification {
            
        case .verified(let transaction):
            guard !inFlightTransactionIDs.contains(transaction.id) else { return nil }
            
            inFlightTransactionIDs.insert(transaction.id)
            defer { inFlightTransactionIDs.remove(transaction.id) }
            
            let response = try await syncPurchase(signedTransaction: verification.jwsRepresentation)
            
            entitlement = response.entitlement
            usage = response.usage
            
            if finishAfterSync {
                await transaction.finish()
            }
            
            return response
            
        case .unverified(_, let verificationError):
            throw PaymentStoreError.unverifiedTransaction(String(describing: verificationError))
        }
    }
    
    
    private func syncPurchase(signedTransaction: String) async throws -> PurchaseSyncResponse {
        
        do {
            let response: PurchaseSyncResponse = try await supabaseDBClient.functions.invoke("user_purchase_sync", options: FunctionInvokeOptions(body: PurchaseSyncRequest(signedTransaction: signedTransaction)))
            return response
            
        } catch FunctionsError.httpError(_, let data) {
            if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) { throw PaymentStoreError.backend(code: envelope.error.errorCode, message: envelope.error.message)
            }
            throw PaymentStoreError.backend(code: "purchase_sync_failed", message: "Rep could not synchronize the StoreKit purchase.")
        }
    }
}
