//
//  PaymentStoreCreditsManager.swift
//  Rep
//
//  Created by alex haidar on 8/16/26.
//

/* Central manager for the user's current shared AI credit bucket.
 Supabase remains authoritative for reserving and consuming credits. */

import Foundation
import Combine


@MainActor
final class CreditBucketsManager: ObservableObject {
    private init() {}
    
    static let shared = CreditBucketsManager()
    let supabase = SupabaseClientManager.shared
    
    @Published private(set) var current_plan: BillingPlanRow?
    @Published private(set) var buckets: [BillingBucketCredits] = []
    @Published private(set) var current_bucket: BillingBucketCredits?

    
    var remaining_credits: Decimal {
        guard let current_bucket else { return 0 }
        return max(current_bucket.allowance - current_bucket.consumed - current_bucket.reserved, 0)
    }
    
    var has_available_credits: Bool {
        self.remaining_credits > 0
    }
    
    
    func ensureUserHasCredits(plan: BillingPlan) async throws {
        if CreditBucketsManager.shared.current_bucket == nil {
            try await CreditBucketsManager.shared.refreshBillingCredits(plan: plan)
        }
        try CreditBucketsManager.shared.requireCredits(1)
    }
    
    
    func canAfford(credits: Decimal) -> Bool {
        guard credits > 0 else {
            return false
        }
        return self.remaining_credits >= credits
    }
    
    
    func requireCredits(_ credits: Decimal) throws {
        guard credits > 0 else { throw CreditBucketError.invalidCreditAmount }
        
        guard self.current_bucket != nil else { throw CreditBucketError.noCurrentBucket }
        guard self.canAfford(credits: credits) else { throw CreditBucketError.insufficientCredits(required: credits, remaining: self.remaining_credits) }
    }
    
    
    func isBucketCurrent(bucket: BillingBucketCredits, date: Date = Date()) -> Bool {
        guard bucket.period_start <= date else { return false }
        
        if let periodEnd = bucket.period_end {
            return date < periodEnd
        }
        
        return bucket.bucket_type == .lifetime
    }
    
    
    func refreshBillingCredits(plan: BillingPlan) async throws {
        let billingPlan = try await self.supabase.fetchBillingPlanTiers(plan: plan)
        let featureId = try await self.supabase.fetchBillingFeatureId(feature: .ai_credits)
        let billingBucket = try await self.supabase.fetchBillingBucketForCrediting(featureId: featureId)
        
        guard self.isBucketCurrent(bucket: billingBucket) else {
            self.current_plan = billingPlan
            self.buckets = [billingBucket]
            self.current_bucket = nil
            throw CreditBucketError.noCurrentBucket
        }
        
        self.current_plan = billingPlan
        self.buckets = [billingBucket]
        self.current_bucket = billingBucket
    }
    
    
    func applyUpdatedBucket(_ bucket: BillingBucketCredits) { 
        if let index = self.buckets.firstIndex(where: { $0.id == bucket.id }) {
            self.buckets[index] = bucket
        } else {
            self.buckets.insert(bucket, at: 0)
        }
        
        if self.isBucketCurrent(bucket: bucket) {
            self.current_bucket = bucket
        }
    }
    
    
    func reset() {
        self.current_plan = nil
        self.current_bucket = nil
        self.buckets = []
    }
}
